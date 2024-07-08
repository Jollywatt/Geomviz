import bpy
from . import server
from . import assets
from . import rigs

class ServerPanel(bpy.types.Panel):
	bl_label = "Geometric algebra server"
	bl_idname = 'SCENE_PT_ga_server'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	def draw(self, context):
		layout = self.layout
		server.data_server.panel_area = context.area

		row = layout.row()
		if server.data_server.running:
			row.label(text=f"Listening on port {server.data_server.port}", icon='RADIOBUT_ON')
		else:
			row.label(text="Idle", icon='RADIOBUT_OFF')

		row = layout.row()
		if server.data_server.running:
			row.operator(server.StopServer.bl_idname, icon="PAUSE")
		else:
			row.operator(server.StartServer.bl_idname, icon="PLAY")

		row = layout.row()
		row.prop(context.scene, 'ga_server_port')

		row = layout.row()
		with server.lock:
			row.label(text=f"Current data: {server.data_server.data}")

		row = layout.row()
		row.operator('ga.get_stuff')


class ScenePanel(bpy.types.Panel):
	bl_label = "Geometric algebra scene"
	bl_idname = 'SCENE_PT_ga_scene'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	hello = None

	def draw(self, context):
		layout = self.layout


		row = layout.row()
		row.prop(context.scene, 'ga_inventory_scene', text="Import from")

		row = layout.row()
		row.prop(context.scene, 'ga_collection', text="Import to")

		row = layout.row()
		row.prop(context.scene, 'ga_inventory_item', text="Item")

		row = layout.row()
		row.operator(rigs.Copy.bl_idname, text="Import item")





class RigPanel(bpy.types.Panel):
	bl_label = "Geometric algebra rig"
	bl_idname = 'COLLECTION_PT_ga_rig'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'collection'

	def draw(self, context):

		layout = self.layout

		row = layout.row()
		row.prop(context.collection, 'ga_rig_script')

		row = layout.row()
		row.prop(context.collection, 'ga_rig_script_input')

		row = layout.row()
		row.operator(rigs.Pose.bl_idname)
