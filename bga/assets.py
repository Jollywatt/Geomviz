import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

def load_assets_scene():
	scenes = ['GA Objects']
	with bpy.data.libraries.load(assets_file) as (data_from, data_to):
		data_to.scenes = scenes

	return scenes[0]


class LoadInventory(bpy.types.Operator):
	bl_label = "Load GA assets scene"
	bl_idname = "ga.load_inventory"

	def execute(self, context):
		scene = load_assets_scene()

		context.scene.ga_inventory_scene = scene
		try:
			context.scene.ga_inventory_item = scene.collection.children[0]
		except IndexError:
			context.scene.ga_inventory_item = None

		return {'FINISHED'}
