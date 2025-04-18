bl_info = {
	"name": "Geomviz",
	"blender": (4, 3, 2),
}

if "bpy" in locals():
	# Runs if add-ons are being reloaded with Refresh
	import importlib
	importlib.reload(utils)
	importlib.reload(server)
	importlib.reload(panels)
	importlib.reload(properties)
	importlib.reload(rigs)
	importlib.reload(assets)
	importlib.reload(scene)
	print('Reloaded')
else:
	# Runs first time add-on is loaded
	from . import utils
	from . import server
	from . import panels
	from . import properties
	from . import rigs
	from . import assets
	from . import scene
	print('Imported')

import bpy

classes = [
	server.StartServer,
	server.StopServer,
	panels.GeomvizPanel,
	rigs.InstantiateRig,
	assets.LoadInventory,
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


if __name__ == "__main__":
	register()