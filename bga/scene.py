from . import rigs

def deselect_all(collection):
	for obj in collection.objects:
		obj.select_set(False)


def empty(scene):
	for child in scene.ga_collection.children:
		scene.ga_collection.children.unlink(child)


def random_data(size=3):
	from random import gauss
	pt = lambda: tuple(gauss() for i in range(3))
	return {
		'Simple Point': [pt() for _ in range(size)],
		'Arrow Vector': [pt() for _ in range(2)],
	}


def sync(scene, data):

	for i, rig in enumerate(scene.ga_collection.children):
		name = rig.ga_copied_from.name

		if name in data and len(data[name]) > 0:
			# reuse existing rig
			arg = data[name].pop(0)
			rigs.pose(rig, arg)
			print(f"use: {rig.name}")
		else:
			# delete unused rig
			scene.ga_collection.children.unlink(rig)
			print(f"del: {rig.name}")

	# add new rigs
	for name, args in data.items():
		for arg in args:
			original = scene.ga_inventory_scene.collection.children[name]

			rig = rigs.duplicate(original)
			rigs.pose(rig, arg)

			scene.ga_collection.children.link(rig)
			deselect_all(rig)
			print(f"add: {rig.name}")
