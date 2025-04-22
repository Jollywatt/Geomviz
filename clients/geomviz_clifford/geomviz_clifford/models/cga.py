import clifford as cl
import clifford.g3c
import clifford.tools.classify as classify

from_vector = lambda mv: mv.value[1:4].tolist()
from_bivector = lambda mv: from_vector(mv*cl.g3c.I_base)

def is_cga(mv: cl.MultiVector):
	return isinstance(mv.layout, cl.ConformalLayout)

def encode(mv: cl.MultiVector):
	geom = classify.classify(mv)
	print(f"Classified as {geom}")
	return encode_blade(geom)

def encode_blade(geom: cl.tools.classify.Blade):
	if isinstance(geom, (classify.Point, classify.PointFlat)):
		return {
			'rig_name': "Point",
			'location': from_vector(geom.location),
		}
	elif isinstance(geom, classify.Tangent[3]):
		return {
			'rig_name': "Spear Disk",
			'location': from_vector(geom.location),
			'rig_parameters': {
				'Radius': (abs(geom.direction))**0.5,
				'Normal': from_bivector(geom.direction),
			}
		}
	elif isinstance(geom, classify.PointPair):
		return {
			'rig_name': "Point Pair",
			'location': from_vector(geom.location),
			'rig_parameters': {
				'Radius': geom.radius,
				'Direction': from_vector(geom.direction),
			}
		}
	elif isinstance(geom, classify.Circle):
		print("eoirugh")
		return {
			'rig_name': "Spear Circle",
			'location': from_vector(geom.location),
			'rig_parameters': {
				'Radius': abs(geom.radius),
				'Normal': from_bivector(geom.direction),
				'Dashed': abs(geom.radius) != geom.radius,
				'Arrow count': 0,
			}
		}
	elif isinstance(geom, (classify.Sphere, classify.Round[1])):
		return {
			'rig_name': "Sphere",
			'location': from_vector(geom.location),
			'rig_parameters': {
				'Radius': abs(geom.radius),
				'Dashed': abs(geom.radius) != geom.radius
			}
		}
	elif isinstance(geom, classify.Line):
		return {
			'rig_name': "Spear Line",
			'location': from_vector(geom.location),
			'rig_parameters': {
				'Direction': from_vector(geom.direction),
				'Arrow count': 0,
			}
		}
	elif isinstance(geom, (classify.Plane, classify.DualFlat[1])):
		if isinstance(geom, classify.DualFlat):
			geom = geom.flat
		return {
			'rig_name': "Plane",
			'location': from_vector(geom.location),
			'show_wire': True,
			'rig_parameters': {
				'Normal': from_bivector(geom.direction),
				'Holes': False,
			}
		}
	elif isinstance(geom, classify.Direction[2]):
		return {
			'rig_name': "Arrow Vector",
			'rig_parameters': {
				'Vector': from_vector(geom.direction),
			}
		}
	elif isinstance(geom, classify.Direction[3]):
		return {
			'rig_name': "Checker Plane",
			'rig_parameters': {
				'Normal': from_bivector(geom.direction),
				'Holes': True,
			}
		}
	else:
		raise NotImplementedError(f"Can't encode {type(geom).__name__}s yet.")

