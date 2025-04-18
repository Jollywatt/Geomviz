import bpy
from os import path

assets_file = path.join(path.dirname(__file__), "assets.blend")

def load_inventory_from_file(assets_file):

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


class LoadInventory(bpy.types.Operator):
	"""Import built-in geomviz rigs as node groups"""
	bl_label = "Load default rigs"
	bl_idname = "geomviz.load_inventory"

	def execute(self, context):

		load_inventory_from_file(assets_file)

		return {'FINISHED'}
