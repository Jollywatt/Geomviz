import bpy
from . import server
from . import panels
from . import properties
from . import rigs
from . import assets

classes = [
	server.StartServer,
	server.StopServer,
	panels.ServerPanel,
	panels.RigPanel,
	assets.GetStuff,
	rigs.Compile,
	rigs.Pose,
]

def register():
	for c in classes:
		bpy.utils.register_class(c)

	properties.register()

def unregister():
	for c in classes:
		bpy.utils.unregister_class(c)
