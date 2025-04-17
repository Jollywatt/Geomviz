import clifford as cl
from clifford import MultiVector

from . import client
from .models import vga, cga

def encode_multivector(mv: MultiVector):

	if cga.is_cga(mv):
		return cga.encode(mv)

	elif isinstance(mv.layout, cl.Layout) and mv.layout.dims == 3:
		return vga.encode(mv)

	else:
		raise NotImplementedError(f"Cannot encode {type(mv)}")



def encode_objects(obj):
	if isinstance(obj, MultiVector):
		return [encode_multivector(obj)]
	elif isinstance(obj, (tuple, list)):
		return sum(map(encode_objects, obj), [])
	else:
		raise NotImplementedError(f"can't encode {obj}")

def encode_and_send(*objs):
	objects = encode_objects(objs)
	data = {'objects': objects}
	client.send_data_to_server(data)