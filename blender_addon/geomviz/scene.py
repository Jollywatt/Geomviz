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

	if data.get("animation", False):
		if "frame_range" in data:
			(s, e) = map(int, data["frame_range"])
			bpy.context.scene.frame_start = s
			bpy.context.scene.frame_end = e
			# bpy.context.scene.frame_current = s
			bpy.ops.screen.animation_cancel()
			bpy.ops.screen.animation_play()
	else:
		bpy.ops.screen.animation_cancel()
		

	count = len(data['objects'])
	return f"Synced {count} {'object' if count == 1 else 'objects'}"

def handle_scene_data(data):
	try:
		print("Synchronising scene...")
		return sync(bpy.context.scene.geomviz_collection, data)
	except utils.UnknownRigError as e:
		return f"Unknown rig: {e.name!r}"
	except utils.RigDataError as e:
		return repr(e)
	except utils.PoseError as e:
		try:
			keys = bpy.data.node_groups[e.name].interface.items_tree.keys()
			return f"Failed to pose {e.name!r}: key {e.key!r} not found in {keys!r}"
		except:
			return f"Failed to pose {e.name!r}: key {e.key!r} not found"
