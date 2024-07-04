import bpy
from . import server

class GAPanel(bpy.types.Panel):
	"""Creates a Panel in the Object properties window"""
	bl_label = "Geometric algebra scene"
	bl_idname = "COLLECTION_PT_ga_panel"
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = "collection"

	def draw(self, context):
		layout = self.layout

		obj = context.collection

		row = layout.row()
		row.label(text="Hello world!", icon='SPHERE')

		row = layout.row()
		row.prop(context.scene, 'ga_server_port')

		row = layout.row()
		if server.data_server.running:
			row.operator(server.StopServer.bl_idname, icon="PAUSE")
		else:
			row.operator(server.StartServer.bl_idname, icon="PLAY")

