import bpy
from . import server
from . import assets

class ServerPanel(bpy.types.Panel):
	bl_label = "Geometric algebra scene"
	bl_idname = 'SCENE_PT_ga_panel'
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
		row.prop(context.scene, 'ga_scene_collection')


		row = layout.row()
		with server.lock:
			row.label(text=f"Current data: {server.data_server.data}")

		row = layout.row()
		row.operator('ga.get_stuff')

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
		row.operator(assets.CompileRig.bl_idname)

		row = layout.row()
		row.prop(context.collection, 'ga_rig_script_input')

		row = layout.row()
		row.operator(assets.PoseRig.bl_idname)
		
