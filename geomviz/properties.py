import bpy

def register():
	bpy.types.Scene.geomviz_server_port = bpy.props.IntProperty(
		name="Server Port",
		description="Port for the external data server.",
		default=8888,
		min=1,
		max=65535
	)

	bpy.types.Scene.geomviz_collection = bpy.props.PointerProperty(
		type=bpy.types.Collection,
		name="Collection for geomviz objects",
		description="Collection insert GA objects into.",
		poll=lambda self, collection: collection.name in self.collection.children,
	)

	bpy.types.Scene.geomviz_inventory_item = bpy.props.PointerProperty(
		type=bpy.types.NodeTree,
		name="Geomviz rig",
		description="Geometry nodes tree defining a geomviz object.",
		poll=lambda self, n: n.name in [n.name for n in bpy.data.node_groups],
	)

	bpy.types.Object.geomviz_nodes = bpy.props.PointerProperty(
		type=bpy.types.NodeTree,
		name="Geomviz object geometry nodes",
		description="Geometry node tree defining a geomviz object.",
		poll=lambda self, n: n.name in [n.name for n in bpy.data.node_groups],
	)
