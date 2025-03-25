import bpy
from . import server
from . import assets
from . import rigs


class ScenePanel(bpy.types.Panel):
	bl_label = "Geometric algebra scene"
	bl_idname = 'SCENE_PT_ga_scene'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	def draw(self, context):
		layout = self.layout
		layout.use_property_split = True

		row = layout.row()
		row.operator(assets.LoadInventory.bl_idname, text="Import default inventory")

		row = layout.row()
		row.prop(context.scene, 'ga_inventory_item', text="Item")

		row = layout.row()
		row.prop(context.scene, 'ga_collection', text="Copy to")

		row = layout.row()
		row.operator(rigs.Copy.bl_idname, text="Copy inventory item")


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
		icon = 'RADIOBUT_ON' if server.data_server.running else 'RADIOBUT_OFF'
		row.label(text=f"{server.data_server.status}", icon=icon)

		row = layout.row()
		if server.data_server.running:
			row.operator(server.StopServer.bl_idname, icon="PAUSE")
		else:
			row.operator(server.StartServer.bl_idname, icon="PLAY")

		row = layout.row()
		row.prop(context.scene, 'ga_server_port')
