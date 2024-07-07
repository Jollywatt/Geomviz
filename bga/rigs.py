import bpy

RIG_FUNCTIONS = {}

def compile_rig(collection):
	code = collection.ga_rig_script.as_string()
	name = collection.name
	RIG_FUNCTIONS[name] = {}
	exec(code, RIG_FUNCTIONS[name])

class Compile(bpy.types.Operator):
	bl_label = "Compile"
	bl_idname = "ga.compile_rig"

	def execute(self, context):
		compile_rig(context.collection)

		return {'FINISHED'}


def copy_rig(original_collection, parent_collection, suffix=None):

	new_collection = original_collection.copy()
	for child in original_collection.children.values():
		new_child = child.copy()
		if suffix is not None:
			new_child.name = f"{child.name}.{suffix}"

		new_collection.children.link(new_child)
		new_collection.children.unlink(child)
		
	parent_collection.children.link(new_collection)



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
		objects = context.collection.objects
		pose_fn(pose_fn_input, objects)


		return {'FINISHED'}