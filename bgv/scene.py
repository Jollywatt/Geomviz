import bpy

from . import rigs

class UnknownRigError(Exception):
	def __init__(self, name):
		self.name = name


def empty(scene):
	for child in scene.ga_collection.children:
		scene.ga_collection.children.unlink(child)


def object_names_by_rig_type(objects):
	d = {}
	for obj in objects:
		if isinstance(obj.ga_type, bpy.types.NodeTree):
			name = obj.ga_type.name
			if name not in d:
				d[name] = []
			d[name].append(obj.name)
	return d

def sync(context, data):
	d = object_names_by_rig_type(bpy.data.objects)

	# clear scene
	for obj in context.scene.ga_collection.objects:
		context.scene.ga_collection.objects.unlink(obj)

	for rig_data in data['scene']:
		rig_name = rig_data['Rig']
		if rig_name in d and len(d[rig_name]) > 0:
			# use existing rig object
			obj_name = d[rig_name].pop(0)
			obj = bpy.data.objects[obj_name]
			rigs.pose(obj, rig_data)
			context.scene.ga_collection.objects.link(obj)
			print(f"use: {obj_name}")

		else:
			# create new rig object
			try:
				nodes = bpy.data.node_groups[rig_name]
			except KeyError as e:
				raise UnknownRigError(rig_name)

			obj = rigs.new(nodes)
			rigs.pose(obj, rig_data)
			context.scene.ga_collection.objects.link(obj)
			print(f"new: {rig_name}")
