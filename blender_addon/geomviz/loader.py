# this script should be executed in a blender file
# it loads the plugin with reloading

import sys
from os import path
import importlib

d = path.join(path.dirname(path.dirname(__file__)), "blender-plugin")
if d not in sys.path:
	sys.path.append(d)

import geomviz

try:
	geomviz.unregister()
except e:
	print("Could not unregister classes:", e)

importlib.reload(geomviz)

geomviz.register()
