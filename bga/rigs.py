import bpy

RIG_FUNCTIONS = {}
RIG_OBJECTS = {}

def get_original(obj):
	return obj if obj.ga_copied_from is None else obj.ga_copied_from


def compile_rig(collection : bpy.types.Collection):
	code = collection.ga_rig_script.as_string()
	name = collection.name
	RIG_FUNCTIONS[name] = {}
	print(f"COMPILING FOR {name}")
	exec(code, RIG_FUNCTIONS[name])


def replace_object_properties(data_block, mapping):
	for attr in data_block.rna_type.properties.keys():
		value = getattr(data_block, attr)
		if type(value) == bpy.types.Object and value in mapping:
			setattr(data_block, attr, mapping[value])


def pose(rig : bpy.types.Collection, arg):
	pose_fn = RIG_FUNCTIONS[rig.name]['pose']

	if rig.name not in RIG_OBJECTS:
		RIG_OBJECTS[rig.name] = {get_original(obj).name:obj for obj in rig.objects}
		print("Cached", RIG_OBJECTS[rig.name])

	pose_fn(arg, RIG_OBJECTS[rig.name])


def copy_rig(original : bpy.types.Collection):

	new = original.copy() # want to preserve properties
	new.ga_copied_from = original

	print(original)
	compile_rig(original)
	RIG_FUNCTIONS[new.name] = RIG_FUNCTIONS[original.name]

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
	bl_label = "Pose rig"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		compile_rig(context.collection)

		arg = eval(context.collection.ga_rig_script_input)
		pose(context.collection, arg)

		return {'FINISHED'}