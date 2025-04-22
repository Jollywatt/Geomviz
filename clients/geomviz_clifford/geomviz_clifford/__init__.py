"""Geomviz for clifford"""
__version__ = '0.0.1'

from . import client
from . import encode

from .magics import BlenderSender

def load_ipython_extension(ipython):
    ipython.register_magics(BlenderSender)
    print("Registered BlenderSender magic")

def blend(*args):
    encode.encode_and_send(value)

try:
    import IPython
except ModuleNotFoundError:
    pass
else:
    ipython = IPython.get_ipython()
    if ipython is not None:
        load_ipython_extension(ipython)
