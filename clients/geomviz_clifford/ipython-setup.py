import sys
from os import path
sys.path.append(path.dirname(__file__))

import IPython
ipython = IPython.get_ipython()
ipython.run_line_magic('load_ext', 'autoreload')
ipython.run_line_magic('autoreload', '2')

import clifford as cl
from clifford.tools.classify import *

globals().update(cl.g3c.blades)
globals().update(cl.g3c.stuff)

import geomviz

geomviz.load_ipython_extension(ipython)
