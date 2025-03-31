import bpy

from . import server
from . import assets
from . import rigs


class ScenePanel(bpy.types.Panel):
	bl_label = "Geomviz inventory"
	bl_idname = 'SCENE_PT_geomviz_scene'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	def draw(self, context):
		layout = self.layout
		layout.use_property_split = True

		row = layout.row()
		row.operator(assets.LoadInventory.bl_idname, text="Import default inventory")

		row = layout.row()
		row.prop(context.scene, 'geomviz_inventory_item')

		row = layout.row()
		row.operator(rigs.Copy.bl_idname)


class ServerPanel(bpy.types.Panel):
	bl_label = "Geomviz server"
	bl_idname = 'SCENE_PT_geomviz_server'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	def draw(self, context):
		layout = self.layout
		layout.use_property_split = True
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
		row.prop(context.scene, 'geomviz_server_port', text="Server port")

		row = layout.row()
		row.prop(context.scene, 'geomviz_collection', text="Destination")


