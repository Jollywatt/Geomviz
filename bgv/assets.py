import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

class LoadInventory(bpy.types.Operator):
	bl_label = "Load GA assets"
	bl_idname = "ga.load_inventory"

	def execute(self, context):

		with bpy.data.libraries.load(assets_file) as (data_from, data_to):

			# purge old node groups of the same name
			# we want to replace them, since we don't need to keep both
			# (which is the default behaviour when names collide)
			for name in data_from.node_groups:
				try:
					node_group = bpy.data.node_groups[name]
				except KeyError:
					pass
				else:
					bpy.data.node_groups.remove(node_group)

			node_groups = data_to.node_groups = data_from.node_groups

		for node_group in node_groups:
			node_group.use_fake_user = True

		return {'FINISHED'}
