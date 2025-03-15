import bpy

class PoseError(Exception):
	def __init__(self, name, key):
		self.name = name
		self.key = key

def get_original(obj):
	return obj if obj.ga_copied_from is None else obj.ga_copied_from



def get_empty_mesh():
	name = "Empty mesh"
	if name not in bpy.data.meshes:
		bpy.data.meshes.new(name)
	return bpy.data.meshes[name]


def new(nodes: bpy.types.NodeTree):

	obj = bpy.data.objects.new(nodes.name, get_empty_mesh())
	obj.ga_type = nodes
	mod = obj.modifiers.new(nodes.name, "NODES")
	mod.node_group = nodes

	return obj



def pose(rig: bpy.types.Object, arg):
	print(arg)

	inputs = rig.ga_type.interface.items_tree
	mod = rig.modifiers[rig.ga_type.name]

	for key, val in arg.items():

		if key == "Location":
			rig.location = val
		else:
			try:
				inp = inputs[key]
			except KeyError:
				raise PoseError(rig.ga_type.name, key)

			mod[inp.identifier] = val
			print(f"set {key} to {val}")

	rig.data.update()







# def replace_object_properties(data_block, mapping):
# 	for attr in data_block.rna_type.properties.keys():
# 		value = getattr(data_block, attr)
# 		if type(value) == bpy.types.Object and value in mapping:
# 			setattr(data_block, attr, mapping[value]) # has caused segfault




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