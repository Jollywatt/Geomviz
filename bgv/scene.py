import bpy

from . import rigs

class UnknownRigError(Exception):
	def __init__(self, name):
		self.name = name

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


def sync(context, data):

	for i, rig in enumerate(context.scene.ga_collection.objects):
		name = rig.ga_type.name

		if name in data and len(data[name]) > 0:
			# reuse existing rig
			arg = data[name].pop(0)
			rigs.pose(rig, arg)
			print(f"use: {rig.name}")
		else:
			# delete unused rig
			context.scene.ga_collection.objects.unlink(rig)
			print(f"del: {rig.name}")

	# add new rigs
	for name, args in data.items():
		try:
			nodes = bpy.data.node_groups[name]
		except KeyError as e:
			raise UnknownRigError(name)

		for arg in args:
			rig = rigs.new(nodes)
			rigs.pose(rig, arg)

			context.scene.ga_collection.objects.link(rig)
			# deselect_all(rig)
			print(f"add: {rig.name}")
