import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

class LoadInventory(bpy.types.Operator):
	bl_label = "Load GA assets"
	bl_idname = "ga.load_inventory"

	def execute(self, context):

		with bpy.data.libraries.load(assets_file) as (data_from, data_to):
			data_to.node_groups = data_from.node_groups

		# try:
		# 	context.scene.ga_inventory_item = scene.collection.children[0]
		# except IndexError:
		# 	context.scene.ga_inventory_item = None

		return {'FINISHED'}
