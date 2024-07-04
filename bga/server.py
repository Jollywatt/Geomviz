import bpy


class DataServer():
	running = False

	def start(self):
		self.running = True

	def stop(self):
		self.running = False


data_server = DataServer()


class StartServer(bpy.types.Operator):
	"""Start the external data server"""
	bl_idname = "ga.start_server"
	bl_label = "Start external data server"

	def execute(self, context):

		data_server.start()

		return {'FINISHED'}

class StopServer(bpy.types.Operator):
	"""Stop the external data server"""
	bl_idname = "ga.stop_server"
	bl_label = "Stop external data server"

	def execute(self, context):

		data_server.stop()

		return {'FINISHED'}