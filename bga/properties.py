import bpy
from bpy import props

def register():
	bpy.types.Scene.ga_server_port = props.IntProperty(
		name="Server Port",
		description="Port for the external data server",
		default=8888,
		min=1,
		max=65535
	)

	bpy.types.Scene.ga_inventory_scene = props.PointerProperty(
		type=bpy.types.Scene,
		name="Inventory scene for GA objects",
		description="Scene which holds GA object templates"
	)

	bpy.types.Scene.ga_inventory_item = props.PointerProperty(
		type=bpy.types.Collection,
		name="Inventory item",
		description="A GA object template collection",
		poll=lambda self, collection: collection.name in self.ga_inventory_scene.collection.children,
	)

	bpy.types.Scene.ga_collection = props.PointerProperty(
		type=bpy.types.Collection,
		name="Destination for GA objects",
		description="Collection to populate with generated GA objects",
		poll=lambda self, collection: collection.name in self.collection.children,
	)

	bpy.types.Collection.ga_rig_script = props.PointerProperty(
		type=bpy.types.Text,
		name="Script",
	)

	bpy.types.Collection.ga_rig_script_input = props.StringProperty(
		name="Pose data",
	)