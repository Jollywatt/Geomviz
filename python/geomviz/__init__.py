"""Geomviz for clifford"""
__version__ = '0.0.1'

from . import client
from . import encode

from .ipython_magics import Abracadabra

def load_ipython_extension(ipython):
    print("Loading stuff")
    ipython.register_magics(Abracadabra)

print("hello")