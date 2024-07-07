import bpy

RIG_FUNCTIONS = {}
RIG_OBJECTS = {}

def compile_rig(collection):
	code = collection.ga_rig_script.as_string()
	name = collection.name
	RIG_FUNCTIONS[name] = {}
	exec(code, RIG_FUNCTIONS[name])


def copy_rig(original : bpy.types.Collection):

	new = original.copy() # want to preserve properties

	new_objects = {obj:obj.copy() for obj in original.objects}

	for obj, new_obj in new_objects.items():
		new.objects.unlink(obj)
		new.objects.link(new_obj)

		# update object pointers in constraints
		for constraint in new_obj.constraints:
			for k in constraint.rna_type.properties.keys():
				v = getattr(constraint, k)
				if v in new_objects:
					setattr(constraint, k, new_objects[v])

	return new

class Copy(bpy.types.Operator):
	bl_label = "Copy rig"
	bl_idname = "ga.copy_rig"

	def execute(self, context):
		original = context.scene.ga_inventory_item
		new = copy_rig(original)
		context.scene.ga_collection.children.link(new)

		return {'FINISHED'}


class SuffixDict(dict):
	def __getitem__(self, key):
		for k, v in self.items():
			if k.startswith(key):
				return v
		super().__getitem__(key)


class Pose(bpy.types.Operator):
	bl_label = "Pose"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		name = context.collection.name
		if name not in RIG_FUNCTIONS:
			compile_rig(context.collection)

		pose_fn_input = eval(context.collection.ga_rig_script_input)
		print("Posing with input:", pose_fn_input)

		pose_fn = RIG_FUNCTIONS[name]['pose']
		objects = SuffixDict(context.collection.objects)

		pose_fn(pose_fn_input, objects)
		# print(objects)


		return {'FINISHED'}