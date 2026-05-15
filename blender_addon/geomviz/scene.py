import bpy

from . import rigs
from . import utils

def object_names_by_rig_type(objects):
	d = {}
	for obj in objects:
		if isinstance(obj.geomviz_nodes, bpy.types.NodeTree):
			name = obj.geomviz_nodes.name
			if name not in d:
				d[name] = []
			d[name].append(obj.name)
	return d

def sync(collection, data):
	d = object_names_by_rig_type(bpy.data.objects)

	# clear scene
	for obj in collection.objects:
		collection.objects.unlink(obj)

	for rig_data in data['objects']:
		try:
			rig_name = rig_data['rig_name']
		except KeyError:
			print(data)
			raise utils.RigDataError("Missing key `rig_name`")
		if rig_name in d and len(d[rig_name]) > 0:
			# use existing rig object
			obj_name = d[rig_name].pop(0)
			obj = bpy.data.objects[obj_name]
			rigs.pose(obj, rig_data)
			collection.objects.link(obj)
			# print(f"use: {obj_name}")

		else:
			# create new rig object
			try:
				nodes = bpy.data.node_groups[rig_name]
			except KeyError as e:
				raise utils.UnknownRigError(rig_name)

			obj = rigs.new(nodes)
			rigs.pose(obj, rig_data)
			collection.objects.link(obj)
			# print(f"new: {rig_name}")

	if data.get("animated", False):
		if "frame_range" in data:
			(s, e) = map(int, data["frame_range"])
			bpy.context.scene.frame_start = s
			bpy.context.scene.frame_end = e
			bpy.ops.screen.animation_cancel()
			bpy.ops.screen.animation_play()
		else:
			print("No frame range specified")
	else:
		bpy.ops.screen.animation_cancel()


	count = len(data['objects'])
	return f"Synced {count} {'object' if count == 1 else 'objects'}"

def render_scene(options):
	if "filepath" not in options:
		raise utils.InvalidDataException("render options missing `filepath` key")

	bpy.context.scene.render.filepath = options["filepath"]
	bpy.ops.render.render(write_still = True)


def handle_scene_data(data):
	print("Synchronising scene...")

	if "render" in data:
		render_scene(data["render"])

	if "objects" in data:
		return sync(bpy.context.scene.geomviz_collection, data)
