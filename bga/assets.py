import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

def load_asset(target_collection):
	with bpy.data.libraries.load(assets_file) as (data_from, data_to):
		data_to.scenes = ['GA Objects']

RIG_MODULES = {}

def compile_rig(collection):
	code = collection.ga_rig_script.as_string()
	name = collection.name
	RIG_MODULES[name] = {}
	exec(code, RIG_MODULES[name])


class CompileRig(bpy.types.Operator):
	bl_label = "Compile"
	bl_idname = "ga.compile_rig"

	def execute(self, context):
		compile_rig(context.collection)

		return {'FINISHED'}


class PoseRig(bpy.types.Operator):
	bl_label = "Pose"
	bl_idname = "ga.pose_rig"

	def execute(self, context):
		name = context.collection.name
		if name not in RIG_MODULES:
			compile_rig(context.collection)

		pose_fn = RIG_MODULES[name]['pose']

		pose_fn_input = eval(context.collection.ga_rig_script_input)
		print("Pose input:", pose_fn_input)

		objects = context.collection.objects
		pose_fn(pose_fn_input, objects)


		return {'FINISHED'}

class GetStuff(bpy.types.Operator):
	bl_label = "Get stuff"
	bl_idname = "ga.get_stuff"

	def execute(self, context):
		load_asset(context.scene.ga_scene_collection)
		print('boop', context.scene.ga_scene_collection)

		return {'FINISHED'}
