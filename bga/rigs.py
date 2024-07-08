import bpy

RIG_FUNCTIONS = {}

def compile_rig(collection):
	code = collection.ga_rig_script.as_string()
	name = collection.name
	RIG_FUNCTIONS[name] = {}
	exec(code, RIG_FUNCTIONS[name])

def replace_object_properties(data_block, mapping):
	for attr in data_block.rna_type.properties.keys():
		value = getattr(data_block, attr)
		if type(value) == bpy.types.Object and value in mapping:
			setattr(data_block, attr, mapping[value])

def copy_rig(original : bpy.types.Collection):

	new = original.copy() # want to preserve properties

	new_objects = {obj:obj.copy() for obj in original.objects}

	for obj, new_obj in new_objects.items():
		new.objects.unlink(obj)
		new.objects.link(new_obj)

		new_obj.ga_copied_from = obj

		# update object pointers in modifiers and constraints
		for modifier in new_obj.modifiers:
			replace_object_properties(modifier, new_objects)
		for constraint in new_obj.constraints:
			replace_object_properties(constraint, new_objects)

	return new

class Copy(bpy.types.Operator):
	bl_label = "Copy rig"
	bl_idname = "ga.copy_rig"

	def execute(self, context):
		original = context.scene.ga_inventory_item
		new = copy_rig(original)
		context.scene.ga_collection.children.link(new)

		return {'FINISHED'}


class Pose(bpy.types.Operator):
	bl_label = "Pose"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		name = context.collection.name
		if name not in RIG_FUNCTIONS:
			compile_rig(context.collection)

		pose_fn_input = eval(context.collection.ga_rig_script_input)

		pose_fn = RIG_FUNCTIONS[name]['pose']
		objects = {obj.name if obj.ga_copied_from is None else obj.ga_copied_from.name:obj for obj in context.collection.objects}

		pose_fn(pose_fn_input, objects)

		return {'FINISHED'}