import bpy

from . import server
from . import assets
from . import rigs

class GeomvizPanel(bpy.types.Panel):
	bl_label = "Geomviz"
	bl_idname = 'SCENE_PT_geomviz'
	bl_space_type = 'PROPERTIES'
	bl_region_type = 'WINDOW'
	bl_context = 'scene'

	def draw(self, context):

		self.layout.use_property_split = True
		self.layout.use_property_decorate = False

		# asset controls

		self.layout.label(text="Rigs:")

		row = self.layout.row(align=True)
		row.operator(assets.LoadInventory.bl_idname, text="Load default rigs")
		row.operator(rigs.InstantiateRig.bl_idname)

		row = self.layout.row(align=True)
		row.prop(context.scene, 'geomviz_inventory_item')

		# server controls
		self.layout.label(text="Server:")

		global server
		row = self.layout.row()
		icon = 'RADIOBUT_ON' if server.data_server.running else 'RADIOBUT_OFF'
		row.label(text=f"{server.data_server.status}", icon=icon)

		row = self.layout.row()
		if server.data_server.running:
			row.operator(server.StopServer.bl_idname, icon="PAUSE")
		else:
			row.operator(server.StartServer.bl_idname, icon="PLAY")

		row = self.layout.row()
		row.prop(context.scene, 'geomviz_server_port')

		row = self.layout.row()
		row.prop(context.scene, 'geomviz_collection')
