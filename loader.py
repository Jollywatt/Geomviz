# this script should be executed in a blender file
# it loads the plugin with reloading

import sys
from os import path
import importlib

d = path.dirname(path.dirname(__file__))
if d not in sys.path:
	sys.path.append(d)

import bga
importlib.reload(bga.assets)
importlib.reload(bga.rigs)
importlib.reload(bga.panels)
importlib.reload(bga.properties)
importlib.reload(bga.server)
importlib.reload(bga)

bga.register()
