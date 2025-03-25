import bpy

class PoseError(Exception):
	def __init__(self, name, key):
		self.name = name
		self.key = key


def empty_mesh():
	name = "Empty mesh"
	if name not in bpy.data.meshes:
		bpy.data.meshes.new(name)
	return bpy.data.meshes[name]


def new(nodes: bpy.types.NodeTree):

	obj = bpy.data.objects.new(nodes.name, empty_mesh())
	obj.ga_type = nodes
	mod = obj.modifiers.new(nodes.name, "NODES")
	mod.node_group = nodes

	return obj


def pose(rig: bpy.types.Object, arg):
	inputs = rig.ga_type.interface.items_tree
	mod = rig.modifiers[rig.ga_type.name]

	for key, val in arg.items():

		if key == "Rig":
			pass
		elif key == "Location":
			rig.location = val
		elif key == "Color":
			rig.color = val
		else:
			try:
				inp = inputs[key]
			except KeyError:
				raise PoseError(rig.ga_type.name, key)

			mod[inp.identifier] = val

	rig.data.update()


class Copy(bpy.types.Operator):
	bl_label = "Insert rig into GA scene"
	bl_idname = "ga.copy_rig"

	def execute(self, context):
		rig = new(context.scene.ga_inventory_item)
		context.scene.ga_collection.objects.link(rig)

		return {'FINISHED'}


class Pose(bpy.types.Operator):
	bl_label = "Pose rig"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		compile_rig(context.collection)

		arg = eval(context.collection.ga_rig_script_input)
		pose(context.collection, arg)

		return {'FINISHED'}
