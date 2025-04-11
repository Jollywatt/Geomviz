# 3D vector/vanilla geometric algebra

from math import sqrt

def encode(mv):
	if mv.grades() == {1}:
		return {
		'rig_name': "Arrow Vector",
		'rig_parameters': {
			"Vector": mv.value[1:4].tolist()
		}
	}
	elif mv.grades() == {2}:
		return {
		'rig_name': "Circle 2-blade",
		'rig_parameters': {
			"Normal": mv.value[5:8].tolist(),
			"Radius": sqrt(abs(mv))
		}
	}
	else:
		raise NotImplementedError
