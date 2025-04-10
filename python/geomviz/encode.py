import clifford as cl
from clifford import MultiVector

from . import client
from . import vga

def interpret_multivector(mv: MultiVector):

	if isinstance(mv.layout, cl.ConformalLayout):
		# conformal
		raise NotImplementedError

	elif isinstance(mv.layout, cl.Layout) and mv.layout.dims == 3:
		# 3D vector/vanilla geometric algebra

		if mv.grades() == {1}:
			return vga.vector
		elif mv.grades() == {2}:
			return vga.bivector
		else:
			raise NotImplementedError


def encode_multivector(mv: MultiVector):
	interpreter = interpret_multivector(mv)
	return interpreter(mv)

def encode_scene(obj):
	if isinstance(obj, MultiVector):
		encoded_objects = [encode_multivector(obj)]
	elif isinstance(obj, (tuple, list)):
		encoded_objects = list(map(encode_multivector, obj))

	return {
		'objects': encoded_objects
	}

def encode_and_send(*objs):
	data = encode_scene(objs)
	client.send_data_to_server(data)