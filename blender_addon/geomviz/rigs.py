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
	except ValueError or TypeError as e:
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


def pose(rig: bpy.types.Object, data):

	rig.animation_data_clear()

	if "location" in data:
		if isanimation(data["location"]):
			xyz_curves = [get_fcurve(rig, data_path="location", index=i) for i in range(3)]
			for frame, xyz in data["location"]["keyframes"]:
				with catch_rig_error(f"Can't set location of {rig.geomviz_nodes.name!r} to {data['location']!r} at frame {frame!r}"):
					for i in range(3):
						xyz_curves[i].keyframe_points.insert(frame, xyz[i], options={'FAST'})
		else:
			with catch_rig_error(f"Can't set location of {rig.geomviz_nodes.name!r} to {data['location']!r}"):
				rig.location = data["location"]
	else:
		rig.location = (0,0,0)

	if "show" in data:
		if isanimation(data["show"]):
			curve = get_fcurve(rig, data_path="hide_viewport")
			for frame, show in data["show"]["keyframes"]:
				curve.keyframe_points.insert(frame, not show, options={'FAST'})
		else:
			rig.hide_viewport = not data["show"]
	else:
		rig.hide_viewport = False


	# ensure modifier points to correct geometry nodes tree
	rig.modifiers[rig.geomviz_nodes.name].node_group = rig.geomviz_nodes

	# reset modifier parameters to default
	sockets = rig.geomviz_nodes.interface.items_tree
	for socket in sockets:
		try:
			rig.modifiers[rig.geomviz_nodes.name][socket.identifier] = socket.default_value
		except AttributeError:
			pass

	if data["rig_name"] == "Mesh":
		pose_mesh(rig, data)

	# set modifier parameters
	if "rig_parameters" in data:
		for key, val in data["rig_parameters"].items():
			try:
				inp = sockets[key]
			except KeyError:
				raise utils.PoseError(rig.geomviz_nodes.name, key, keys=sockets.keys())

			if isanimation(val):
				data_path = f'modifiers["{rig.geomviz_nodes.name}"]["{inp.identifier}"]'
				is_vector_like = inp.socket_type in ('NodeSocketVector',)
				if is_vector_like:
					for i in range(len(inp.default_value)):
						fcurve = get_fcurve(rig, data_path, index=i)
						for frame, v in val["keyframes"]:
							with catch_rig_error(f"Can't set {key!r}[{i}] property of {rig.geomviz_nodes.name!r} ({inp.identifier!r}) to {v!r} at frame {frame!r}"):
								fcurve.keyframe_points.insert(frame, v[i])
						for pt in fcurve.keyframe_points:
							pt.interpolation = 'CONSTANT'
				else:
					fcurve = get_fcurve(rig, data_path, index=0)
					for frame, v in val["keyframes"]:
						with catch_rig_error(f"Can't set {key!r} property of {rig.geomviz_nodes.name!r} ({inp.identifier!r}) to {v!r} at frame {frame!r}"):
							fcurve.keyframe_points.insert(frame, v)
					for pt in fcurve.keyframe_points:
						pt.interpolation = 'CONSTANT'

			else:
				with catch_rig_error(f"Can't set {key!r} property of {rig.geomviz_nodes.name!r} ({inp.identifier!r}) to {val!r}"):
					rig.modifiers[rig.geomviz_nodes.name][inp.identifier] = val


	if "color" in data:
		if isanimation(data["color"]):
			raise utils.RigDataError("Can't animate color yet")
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
