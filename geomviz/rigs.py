import bpy

from . import utils

def empty_mesh():
	name = "Empty mesh"
	if name not in bpy.data.meshes:
		bpy.data.meshes.new(name)
	return bpy.data.meshes[name]


def new(nodes: bpy.types.NodeTree):
	obj = bpy.data.objects.new(nodes.name, empty_mesh())
	obj.geomviz_nodes = nodes
	mod = obj.modifiers.new(nodes.name, "NODES")
	mod.node_group = nodes
	return obj


def isanimation(obj):
	return isinstance(obj, dict) and "keyframes" in obj

def get_action(obj):
	obj.animation_data_create()
	if obj.animation_data.action is None:
		action = bpy.data.actions.new(f"{obj.name} action")
		obj.animation_data.action = action
	return obj.animation_data.action


def get_fcurve(obj, data_path, index=0):
	action = get_action(obj)
	fcurve = action.fcurves.find(data_path, index=index)
	if fcurve is None:
		fcurve = action.fcurves.new(data_path, index=index)
	return fcurve

def clear_fcurve(obj, data_path, index=0):
	action = obj.animation_data.action
	if action is not None:
		fcurve = action.fcurves.find(data_path, index=index)
		if fcurve is not None:
			action.fcurves.remove(fcurve)

def pose(rig: bpy.types.Object, data):

	rig.animation_data_clear()

	if "location" in data:
		if isanimation(data["location"]):
			xyz_curves = [get_fcurve(rig, data_path="location", index=i) for i in range(3)]
			for frame, xyz in data["location"]["keyframes"]:
				for i in range(3):
					xyz_curves[i].keyframe_points.insert(frame, xyz[i], options={'FAST'})
		else:
			rig.location = data["location"]
	else:
		rig.location = (0,0,0)

	# reset modifier parameters to default
	sockets = rig.geomviz_nodes.interface.items_tree
	for socket in sockets:
		try:
			rig.modifiers[rig.geomviz_nodes.name][socket.identifier] = socket.default_value
		except AttributeError:
			pass

	# set modifier parameters
	if "rig_parameters" in data:
		for key, val in data["rig_parameters"].items():
			try:
				inp = sockets[key]
			except KeyError:
				# raise utils.PoseError(rig.geomviz_nodes.name, key)
				print(f"WARNING: rig {rig.geomviz_nodes.name!r} has no parameter {key!r}")
				continue

			if isanimation(val):
				data_path = f'modifiers["{rig.geomviz_nodes.name}"]["{inp.identifier}"]'
				is_vector_like = inp.socket_type in ('NodeSocketVector',)
				if is_vector_like:
					for i in range(len(inp.default_value)):
						fcurve = get_fcurve(rig, data_path, index=i)
						for frame, v in val["keyframes"]:
							try:
								fcurve.keyframe_points.insert(frame, v[i])
							except TypeError as e:
								print(e)
								raise utils.RigDataError(f"can't set {rig.geomviz_nodes.name!r} socket {key!r}[{i}] ({inp.identifier!r}) to {v!r} at frame {frame!r}")
				else:
					fcurve = get_fcurve(rig, data_path, index=0)
					for frame, v in val["keyframes"]:
						try:
							fcurve.keyframe_points.insert(frame, v)
						except TypeError as e:
							print(e)
							raise utils.RigDataError(f"can't set {rig.geomviz_nodes.name!r} socket {key!r}[{i}] ({inp.identifier!r}) to {v!r} at frame {frame!r}")


			else:
				try:
					rig.modifiers[rig.geomviz_nodes.name][inp.identifier] = val
				except TypeError as e:
					# print()
					print(e)
					raise utils.RigDataError(f"can't set {rig.geomviz_nodes.name!r} socket {key!r} to {val!r}")


	if "color" in data:
		if isanimation(data["color"]):
			raise utils.RigDataError("can't animate color yet")
		else:
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

	def execute(self, context):
		item = context.scene.geomviz_inventory_item
		if item is None:
			utils.error_popup(context, "No item selected")
			return {'CANCELLED'}

		rig = new(item)
		context.scene.geomviz_collection.objects.link(rig)

		return {'FINISHED'}
