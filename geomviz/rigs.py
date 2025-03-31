import bpy

from . import utils

def empty_mesh():
	name = "Empty mesh"
	if name not in bpy.data.meshes:
		bpy.data.meshes.new(name)
	return bpy.data.meshes[name]


def new(nodes: bpy.types.NodeTree):

	obj = bpy.data.objects.new(nodes.name, empty_mesh())
	obj.geomviz_nodes = nodes
	mod = obj.modifiers.new(nodes.name, "NODES")
	mod.node_group = nodes

	return obj


def pose(rig: bpy.types.Object, arg):
	inputs = rig.geomviz_nodes.interface.items_tree
	mod = rig.modifiers[rig.geomviz_nodes.name]

	for key, val in arg.items():

		if key == "Rig":
			pass
		elif key == "Location":
			rig.location = val
		elif key == "Color":
			rig.color = val
		elif key == "Show wire":
			rig.show_wire = val
		else:
			try:
				inp = inputs[key]
			except KeyError:
				raise utils.PoseError(rig.geomviz_nodes.name, key)

			mod[inp.identifier] = val

	rig.data.update()


class Copy(bpy.types.Operator):
	bl_label = "Insert rig into GA scene"
	bl_idname = "geomviz.copy_rig"

	def execute(self, context):
		rig = new(context.scene.geomviz_inventory_item)
		context.scene.geomviz_collection.objects.link(rig)

		return {'FINISHED'}


class Pose(bpy.types.Operator):
	bl_label = "Pose rig"
	bl_idname = "geomviz.pose_rig"

	def execute(self, context):
		compile_rig(context.collection)

		arg = eval(context.collection.geomviz_rig_script_input)
		pose(context.collection, arg)

		return {'FINISHED'}
