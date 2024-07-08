# this script should be executed in a blender file
# it loads the plugin with reloading

import sys
from os import path
import importlib

d = path.dirname(path.dirname(__file__))
if d not in sys.path:
	sys.path.append(d)

import bgv
importlib.reload(bgv.assets)
importlib.reload(bgv.rigs)
importlib.reload(bgv.panels)
importlib.reload(bgv.properties)
importlib.reload(bgv.server)
importlib.reload(bgv)

bgv.register()
