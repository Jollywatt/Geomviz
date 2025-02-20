import bpy
import threading
import socket
import pickle

from . import scene

lock = threading.Lock()

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
	data = None
	panel_area = None
	scene = None
	sock = None

	def start(self, port=8888):
		self.port = port

		self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		self.sock.settimeout(1)
		try:
			self.sock.bind(('127.0.0.1', self.port))
		except OSError as e:
			print(f"Server error: {e}")
			return

		try:
			self.sock.listen()
			self.running = True
			print(f"Listening on port {self.port}...")

			while self.running:
				try:
					conn, addr = self.sock.accept()
				except socket.timeout:
					pass
				except:
					raise
				else:
					self.handle_client(conn)
		finally:
			self.sock.close()
			print(f"No longer listening on port {self.port}.")

	def stop(self):
		self.running = False

	def handle_client(self, conn):
		binary = conn.recv(1 << 12)

		try:
			data = validate_data(binary)
			print(f"Received {data!r}.")
		except Exception as e:
			conn.send(f"Your data sucks!\n{e}".encode())
			conn.close()
		else:
			conn.send("Received.".encode())
			conn.close()
			with lock:
				self.data = data
		finally:
			self.trigger_update()

	def trigger_update(self):
		if type(self.panel_area) is bpy.types.Area:
			self.panel_area.tag_redraw()

		if self.data is not None:
			scene.sync(self.scene, self.data)


class StartServer(bpy.types.Operator):
	"""Start the external data server"""
	bl_idname = "ga.start_server"
	bl_label = "Start external data server"

	def execute(self, context):

		port = context.scene.ga_server_port
		def serve():
			try:
				data_server.start(port)
			finally:
				print("THREAD ENDING: running finally block")
				data_server.stop()

		data_server.scene = context.scene
		thread = threading.Thread(target=serve)
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

