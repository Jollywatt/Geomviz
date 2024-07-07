import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

def load_asset(target_collection):
	with bpy.data.libraries.load(assets_file) as (data_from, data_to):
		data_to.scenes = ['GA Objects']


class GetStuff(bpy.types.Operator):
	bl_label = "Get stuff"
	bl_idname = "ga.get_stuff"

	def execute(self, context):
		load_asset(context.scene.ga_scene_collection)
		print('boop', context.scene.ga_scene_collection)

		return {'FINISHED'}
