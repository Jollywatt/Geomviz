import bpy
from . import server
from . import panels
from . import properties
from . import rigs
from . import assets

classes = [
	server.StartServer,
	server.StopServer,
	panels.ScenePanel,
	panels.ServerPanel,
	panels.RigPanel,
	assets.LoadInventory,
	rigs.Pose,
	rigs.Copy,
]

def register():
	for c in classes:
		bpy.utils.register_class(c)

	properties.register()

def unregister():
	for c in classes:
		try:
			bpy.utils.unregister_class(c)
		except Exception as e:
			print(f"Failed to unregister: {e}")
