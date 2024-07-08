import bpy

RIG_FUNCTIONS = {}

def get_original(obj):
	return obj if obj.ga_copied_from is None else obj.ga_copied_from


def compile_rig(collection : bpy.types.Collection, recompile=True):
	name = collection.name
	if not recompile and name in RIG_FUNCTIONS:
		return

	RIG_FUNCTIONS[name] = {}

	code = collection.ga_rig_script.as_string()
	print(f"COMPILING FOR {name}")
	exec(code, RIG_FUNCTIONS[name])


def pose(rig : bpy.types.Collection, arg):
	if rig.name not in RIG_FUNCTIONS:
		original = rig.ga_copied_from
		compile_rig(original, recompile=False)
		RIG_FUNCTIONS[rig.name] = RIG_FUNCTIONS[original.name]

	pose_fn = RIG_FUNCTIONS[rig.name]['pose']

	objects_by_name = {get_original(obj).name:obj for obj in rig.objects}

	pose_fn(arg, objects_by_name)


def replace_object_properties(data_block, mapping):
	for attr in data_block.rna_type.properties.keys():
		value = getattr(data_block, attr)
		if type(value) == bpy.types.Object and value in mapping:
			setattr(data_block, attr, mapping[value])


def duplicate(original : bpy.types.Collection):

	new = original.copy() # want to preserve properties
	new.ga_copied_from = original

	compile_rig(original, recompile=False)
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
		new = duplicate(original)
		context.scene.ga_collection.children.link(new)

		return {'FINISHED'}


class Pose(bpy.types.Operator):
	bl_label = "Pose rig"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		compile_rig(context.collection)

		arg = eval(context.collection.ga_rig_script_input)
		pose(context.collection, arg)

		return {'FINISHED'}>>>>>>>
