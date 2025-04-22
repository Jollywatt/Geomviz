import clifford as cl

from . import client
from .models import vga, cga

encodings = {
	
}

def encode_multivector(mv: cl.MultiVector):

	if cga.is_cga(mv):
		return cga.encode(mv)

	elif isinstance(mv.layout, cl.Layout) and mv.layout.dims == 3:
		return vga.encode(mv)

	elif mv.layout in encodings:
		encoder = encodings[mv.layout]
		return encoder(mv)

	else:
		raise NotImplementedError(f"Cannot encode multivector {type(mv)}")



def encode_objects(obj):
	if isinstance(obj, cl.MultiVector):
		return [encode_multivector(obj)]
	elif isinstance(obj, (tuple, list, cl.MVArray)):
		return sum(map(encode_objects, obj), [])
	else:
		raise NotImplementedError(f"Can't encode object {obj}")

def encode_and_send(*objs):
	objects = encode_objects(objs)
	data = {'objects': objects}
	client.send_data_to_server(data)