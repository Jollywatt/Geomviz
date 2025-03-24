import bpy

from . import rigs

class UnknownRigError(Exception):
	def __init__(self, name):
		self.name = name


def empty(scene):
	for child in scene.ga_collection.children:
		scene.ga_collection.children.unlink(child)


def sync(context, data):

	# for i, rig in enumerate(context.scene.ga_collection.objects):
	for i, rig in enumerate(bpy.data.objects):
		ga_type = rig.ga_type
		if not isinstance(ga_type, bpy.types.NodeTree):
			continue
		name = ga_type.name
		print(f"considering {rig}, a {name}")

		if name in data and len(data[name]) > 0:
			# reuse existing rig
			arg = data[name].pop(0)
			rigs.pose(rig, arg)

			try:
				context.scene.ga_collection.objects.link(rig)
				print(f"use: {rig.name}")
			except RuntimeError:
				pass
		else:
			# delete unused rig
			try:
				context.scene.ga_collection.objects.unlink(rig)
				print(f"del: {rig.name}")
			except RuntimeError:
				pass

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
			print(f"new: {rig.name}")
