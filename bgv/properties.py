import bpy
from bpy import props

def register():
	bpy.types.Scene.ga_server_port = props.IntProperty(
		name="Server Port",
		description="Port for the external data server.",
		default=8888,
		min=1,
		max=65535
	)

	bpy.types.Scene.ga_collection = props.PointerProperty(
		type=bpy.types.Collection,
		name="Destination for GA objects",
		description="Collection insert GA objects into.",
		poll=lambda self, collection: collection.name in self.collection.children,
	)

	bpy.types.Scene.ga_inventory_item = props.PointerProperty(
		type=bpy.types.NodeTree,
		name="Inventory item",
		description="Geometry nodes defining a GA inventory item.",
		poll=lambda self, n: n.name in [n.name for n in bpy.data.node_groups],
	)

	bpy.types.Object.ga_type = props.PointerProperty(
		type=bpy.types.NodeTree,
		name="GA object geometry nodes",
		description="Geometry nodes defining this GA object.",
		poll=lambda self, n: n.name in [n.name for n in bpy.data.node_groups],
	)