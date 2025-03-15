import bpy
import threading
import socket
import pickle
import queue

from . import rigs
from . import scene

class InvalidDataException(Exception):
	pass

def validate_data(binary):
	try:
		data = pickle.loads(binary)
	except Exception as e:
		raise InvalidDataException(e)
	else:
		if type(data) is not dict:
			raise InvalidDataException(f"Data is of unexpected type {type(data)}.")
		return data


class DataServer():
	running = False
	port = None
	panel_area = None
	status = "Idle"

	def start(self, port=8888):
		self.running = True
		self.port = port

		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			try:
				sock.bind(('127.0.0.1', self.port))
			except OSError as e:
				self.set_status(f"Error: {e}")
				return

			sock.settimeout(1)
			sock.listen()
			self.set_status(f"Listening on port {self.port}...")

			while self.running:
				try:
					conn, addr = sock.accept()
				except socket.timeout:
					pass
				except:
					raise
				else:
					self.handle_client(conn)

		print(f"Closing socket on port {self.port}.")

	def stop(self):
		if self.running:
			self.set_status("Idle")
		self.running = False

	def handle_client(self, conn):
		binary = conn.recv(1 << 15)

		try:
			data = validate_data(binary)
			print(f"Received {data!r}.")

		except Exception as e:
			conn.send(f"Your data sucks!\n{e}".encode())
			conn.close()
			print(e)
		else:
			conn.send("Received.".encode())
			conn.close()

			try:
				data_queue.put(data)
			except Exception as e:
				print("Couldn't put to queue")
				print(e)

	def set_status(self, status):
		self.status = status
		print(f"Status: {status}")
		if type(self.panel_area) is bpy.types.Area:
			self.panel_area.tag_redraw()


data_queue = queue.Queue()


class StartServer(bpy.types.Operator):
	"""Start the external data server"""
	bl_idname = "ga.start_server"
	bl_label = "Start external data server"

	def execute(self, context):

		port = context.scene.ga_server_port
		data_server.running = True
		thread = threading.Thread(target=data_server.start, args=(port,))

		def handle_queue():
			while not data_queue.empty():
				data = data_queue.get()
				print("Syncronising scene")

				try:
					scene.sync(context, data)
				except scene.UnknownRigError as e:
					print(f"Unknown rig: {e.name!r}")
				except rigs.PoseError as e:
					print(f"Failed to pose {e.name!r}: key {e.key!r} not found")

				data_queue.task_done()

			if data_server.running:
				return 1/60

			print("CLOSING TIMER")


		bpy.app.timers.register(handle_queue)
		thread.start()

		return {'FINISHED'}


class StopServer(bpy.types.Operator):
	"""Stop the external data server"""
	bl_idname = "ga.stop_server"
	bl_label = "Stop external data server"

	def execute(self, context):
		data_server.stop()

		return {'FINISHED'}


# have one server in the global scope
try:
	# if module already loaded, a server instance already exists.
	# stop the old server if necessary
	data_server.stop()
	print("Stopped existing server")
except NameError:
	pass

data_server = DataServer()

