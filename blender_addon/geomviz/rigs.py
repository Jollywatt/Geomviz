import bpy
from bpy_extras.anim_utils import action_ensure_channelbag_for_slot
from . import utils
from contextlib import contextmanager

def empty_mesh(reuse=True):
	name = "Empty mesh" if reuse else "Mesh"
	if reuse and name in bpy.data.meshes:
		mesh = bpy.data.meshes[name]
	else:
		mesh = bpy.data.meshes.new(name)
	return mesh


def new(nodes: bpy.types.NodeTree):
	reuse = False if nodes.name == "Mesh" else True
	obj = bpy.data.objects.new(nodes.name, empty_mesh(reuse))
	obj.geomviz_nodes = nodes
	mod = obj.modifiers.new(nodes.name, "NODES")
	mod.node_group = nodes
	print(f"new with mesh name {obj.data.name}")
	return obj


def isanimation(obj):
	return isinstance(obj, dict) and "keyframes" in obj

@contextmanager
def catch_rig_error(label):
	try:
		yield
	except (ValueError, TypeError) as e:
		raise utils.RigDataError(label, detail=e)

def get_channelbag(obj):
	obj.animation_data_create()
	if obj.animation_data.action is None:
		action = bpy.data.actions.new(f"{obj.name} action")
		obj.animation_data.action = action
		obj.animation_data.action_slot = action.slots.new('OBJECT', obj.name)
	return action_ensure_channelbag_for_slot(obj.animation_data.action, obj.animation_data.action_slot)

def get_fcurve(obj, data_path, index=0):
	channelbag = get_channelbag(obj)
	fcurve = channelbag.fcurves.ensure(data_path, index=index, group_name=f"Geomviz Rig")
	return fcurve


def pose_mesh(rig: bpy.types.Object, data):
	rig.data.clear_geometry()
	# rig.update_from_editmode() # ensure object mode
	vertices = data["vertices"]
	edges = data.get("edges", [])
	faces = data.get("faces", [])
	try:
		rig.data.from_pydata(vertices, edges, faces) # fails in edit mode
	except RuntimeError as e:
		raise utils.GeomvizError(f"Mesh rig: {e}")

	rig.data.validate()
	rig.update_from_editmode() # ensure object mode


def animate_scalar_property(rig, data_path, keyframes, label=None):
	curve = get_fcurve(rig, data_path=data_path)
	curve.keyframe_points.add(len(keyframes))
	for i, (frame, val) in enumerate(keyframes):
		with catch_rig_error(f"Can't set property {label or data_path!r} of {rig.geomviz_nodes.name!r} to {val!r} at frame {frame!r}"):
			curve.keyframe_points[i].co = (frame, val)
			curve.keyframe_points[i].interpolation = 'CONSTANT'

def animate_vector_property(rig, data_path, keyframes, vector_len, label=None):
	curves = [get_fcurve(rig, data_path=data_path, index=ax) for ax in range(vector_len)]
	for curve in curves:
		curve.keyframe_points.add(len(keyframes))
	for i, (frame, vals) in enumerate(keyframes):
		if len(vals) != vector_len:
			raise utils.RigDataError(f"Vector property {label or data_path!r} must have size {vector_len}; got {vals!r}")
		with catch_rig_error(f"Can't set vector property {label or data_path!r} of {rig.geomviz_nodes.name!r} to {vals!r} at frame {frame!r}"):
			for ax in range(vector_len):
				curves[ax].keyframe_points[i].co = (frame, vals[ax])
				curves[ax].keyframe_points[i].interpolation = 'CONSTANT'

def pose(rig: bpy.types.Object, data):

	rig.animation_data_clear()

	if "location" in data:
		if isanimation(data["location"]):
			animate_vector_property(rig, "location", data["location"]["keyframes"], vector_len=3)
		else:
			with catch_rig_error(f"Can't set location of {rig.geomviz_nodes.name!r} to {data['location']!r}"):
				rig.location = data["location"]
	else:
		rig.location = (0,0,0)

	if "show" in data:
		if isanimation(data["show"]):
			keyframes = [(frame, not show) for frame, show in data["show"]["keyframes"]]
			animate_scalar_property(rig, "hide_viewport", keyframes)
			animate_scalar_property(rig, "hide_render", keyframes)
		else:
			rig.hide_viewport = not data["show"]
			rig.hide_render = not data["show"]
	else:
		rig.hide_viewport = False
		rig.hide_render = False


	if data["rig_name"] == "Mesh":
		pose_mesh(rig, data)

	# ensure modifier points to correct geometry nodes tree
	rig.modifiers[rig.geomviz_nodes.name].node_group = rig.geomviz_nodes

	sockets_by_name = {}
	for item in rig.geomviz_nodes.interface.items_tree:
		if hasattr(item, 'identifier'): # ignore panels and non-sockets
			sockets_by_name[item.name] = item

	# reset modifier parameters to default
	for name, socket in sockets_by_name.items():
		try:
			rig.modifiers[rig.geomviz_nodes.name][socket.identifier] = socket.default_value
		except AttributeError:
			pass # some sockets (e.g. geometry sockets) don't have default values

	# set modifier parameters
	if "rig_parameters" in data:
		for key, val in data["rig_parameters"].items():
			try:
				socket = sockets_by_name[key]
			except KeyError:
				raise utils.PoseError(rig.geomviz_nodes.name, key, keys=list(sockets_by_name.keys()))

			if isanimation(val):
				data_path = f'modifiers["{rig.geomviz_nodes.name}"]["{socket.identifier}"]'
				is_vector_like = socket.socket_type in ('NodeSocketVector',)
				if is_vector_like:
					animate_vector_property(rig, data_path, val["keyframes"], label=key, vector_len=len(socket.default_value))
				else:
					animate_scalar_property(rig, data_path, val["keyframes"], label=key)

			else:
				with catch_rig_error(f"Can't set {key!r} property of {rig.geomviz_nodes.name!r} ({socket.identifier!r}) to {val!r}"):
					rig.modifiers[rig.geomviz_nodes.name][socket.identifier] = val


	if "color" in data:
		if isanimation(data["color"]):
			animate_vector_property(rig, "color", data["color"]["keyframes"], vector_len=4)
		else:
			with catch_rig_error(f"Can't set color of {rig.geomviz_nodes.name!r} to {data['color']!r}"):
				rig.color = data["color"]
	else:
		rig.color = (1,1,1,1)

	if "show_wire" in data:
		rig.show_wire = data["show_wire"]

	if "name" in data:
		rig.name = data["name"]
		rig.show_name = True
	else:
		rig.name = data["rig_name"]
		rig.show_name = False

	rig.data.update()



class InstantiateRig(bpy.types.Operator):
	"""Create an object with the selected geomviz rig"""
	bl_label = "Insert rig"
	bl_idname = "geomviz.copy_rig"

	@classmethod
	def poll(self, context):
		if context.scene.geomviz_collection is None:
			self.poll_message_set("Select a destination collection first.")
			return False
		elif context.scene.geomviz_inventory_item is None:
			self.poll_message_set("Select a rig node group first.")
			return False
		else:
			return True

	def execute(self, context):
		item = context.scene.geomviz_inventory_item
		if item is None:
			utils.error_popup(context, "No item selected")
			return {'CANCELLED'}

		rig = new(item)
		context.scene.geomviz_collection.objects.link(rig)

		return {'FINISHED'}
