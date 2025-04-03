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

	if "rig_parameters" in data:
		inputs = rig.geomviz_nodes.interface.items_tree
		for key, val in data["rig_parameters"].items():
			try:
				inp = inputs[key]
			except KeyError:
				raise utils.PoseError(rig.geomviz_nodes.name, key)

			data_path = f'modifiers["{rig.geomviz_nodes.name}"]["{inp.identifier}"]'
			if isanimation(val):
				fcurve = get_fcurve(rig, data_path)
				for frame, v in val["keyframes"]:
					fcurve.keyframe_points.insert(frame, v)
			else:
				rig.modifiers[rig.geomviz_nodes.name][inp.identifier] = val


	if "color" in data:
		if isanimation(data["color"]):
			raise utils.RigDataError("can't animate color yet")
		else:
			rig.color = data["color"]

	if "show_wire" in data:
		rig.show_wire = data["show_wire"]

	if "name" in data:
		rig.name = data["name"]
		rig.show_name = True
	else:
		rig.name = data["rig_name"]
		rig.show_name = False


	# 	if key == "Rig":
	# 		pass
	# 	elif key == "Location":
	# 		rig.location = val
	# 	elif key == "Color":
	# 		rig.color = val
	# 	elif key == "Show wire":
	# 		rig.show_wire = val
	# 	else:
	# 		try:
	# 			inp = inputs[key]
	# 		except KeyError:
	# 			raise utils.PoseError(rig.geomviz_nodes.name, key)

	# 		mod[inp.identifier] = val

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
