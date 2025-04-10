from math import sqrt

def vector(mv):
	return {
		'rig_name': "Arrow Vector",
		'rig_parameters': {
			"Vector": mv.value[1:4].tolist()
		}
	}

def bivector(mv):
	return {
		'rig_name': "Circle 2-blade",
		'rig_parameters': {
			"Normal": mv.value[5:8].tolist(),
			"Radius": sqrt(abs(mv))
		}
	}