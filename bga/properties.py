from bpy import props
from bpy.types import Scene

def register():
	Scene.ga_server_port = props.IntProperty(
		name="Server Port",
		description="Port for the external data server",
		default=8888,
		min=1,
		max=65535
	)