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

	bpy.types.Scene.ga_scene_collection = props.PointerProperty(
		type=bpy.types.Collection,
		name="Destination",
		description="Collection to populate with GA objects"
	)

	bpy.types.Collection.ga_rig_script = props.PointerProperty(
		type=bpy.types.Text,
		name="Script",
	)

	bpy.types.Collection.ga_rig_script_input = props.StringProperty(
		name="Pose data",
	)
