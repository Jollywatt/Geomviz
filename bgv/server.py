import bpy
import threading
import socket
import pickle
import queue

from . import scene

lock = threading.Lock()
scene_queue = queue.Queue()


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
	status = "Idle"
	scene = None
	sock = None

	def start(self, port=8888):
		self.port = port

		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.settimeout(1)
		try:
			sock.bind(('127.0.0.1', self.port))
		except OSError as e:
			self.set_status(f"Error: {e}")
			return

		try:
			sock.listen()
			self.running = True
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

		finally:
			sock.close()
			print(f"Closing socket on port {self.port}.")

	def stop(self):
		self.running = False
		self.set_status("Idle")

		if bpy.app.timers.is_registered(consume_queue):
			bpy.app.timers.unregister(consume_queue)


	def handle_client(self, conn):
		binary = conn.recv(1 << 12)

		try:
			data = validate_data(binary)
			print(f"Received {data!r}.")
			try:
				scene_queue.put(data)
			except Exception as e:
				print("Couldn't put to queue")
				print(e)

		except Exception as e:
			conn.send(f"Your data sucks!\n{e}".encode())
			conn.close()
		else:
			conn.send("Received.".encode())
			conn.close()

	def set_status(self, status):
		self.status = status
		print(f"Status: {status}")
		if type(self.panel_area) is bpy.types.Area:
			self.panel_area.tag_redraw()


def consume_queue():
	while not scene_queue.empty():
		data = scene_queue.get()
		print("Syncronising scene")
		scene.sync(data_server.scene, data)
		scene_queue.task_done()

	return 1/60


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

		bpy.app.timers.register(consume_queue)

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

