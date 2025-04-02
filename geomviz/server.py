import bpy
import threading
import socket
import pickle
import queue
from time import time

from . import rigs
from . import scene
from . import utils

def validate_data(binary):
	try:
		data = pickle.loads(binary)
	except Exception as e:
		raise utils.InvalidDataException(e)
	else:
		if type(data) is not dict:
			raise utils.InvalidDataException(f"Data is of unexpected type {type(data)}.")
		# if 'scene' not in data:
		# 	raise utils.InvalidDataException(f"Data is missing 'scene' key: {data!r}.")
		# for rig in data['scene']:
		# 	if 'Rig' not in rig:
		# 		raise utils.InvalidDataException(f"Rig data is missing 'Rig' key: {data!r}.")

		return data

class DataServer():
	running = False
	port = None
	panel_area = None
	status = "Idle"
	data_queue = queue.Queue()
	heartbeat = 0.

	def set_status(self, status):
		self.status = status
		print(f"DataServer status: {status}")
		if isinstance(self.panel_area, bpy.types.Area):
			self.panel_area.tag_redraw()

	def start(self, port):
		self.port = port

		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

			try:
				sock.bind(('127.0.0.1', self.port))
			except OSError as e:
				self.set_status(f"Error: {e}")
				return

			sock.settimeout(1)
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
					self.put_to_queue(conn)

				# check that the main thread is still alive
				if time() - self.heartbeat > 1:
					# end server thread to avoid hanging blender on exit
					break

		print(f"Closing socket on port {self.port}.")

	def start_async(self, port):
		self.running = True

		global geomviz_timer_pointer
		geomviz_timer_pointer = lambda: self.read_from_queue()
		bpy.app.timers.register(geomviz_timer_pointer)

		thread = threading.Thread(target=data_server.start, args=(port,))
		thread.start()

	def stop(self):
		if self.running:
			self.set_status("Stopped")
			print("Stopped existing running server")

		global geomviz_timer_pointer
		try:
			bpy.app.timers.unregister(geomviz_timer_pointer)
		except ValueError:
			pass

		self.running = False

	def put_to_queue(self, conn):
		# this runs in the server's thread
		# leaving data in the queue to be read by the main thread
		binary = conn.recv(1 << 16)
		try:
			data = validate_data(binary)
			print(f"Received {data!r}.")
		except Exception as e:
			conn.send(f"Your data sucks!\n{e}".encode())
			conn.close()
			self.set_status(f"Error: {e}")
		else:
			conn.send("Received.".encode())
			conn.close()
			self.data_queue.put(data)
			print(f"Queued {data}")

	def read_from_queue(self):
		# this runs as a registered bpy.app timer
		# reading data left by the server's thread in the shared queue
		while not self.data_queue.empty():
			data = self.data_queue.get()
			status = scene.handle_scene_data(data)
			self.set_status("Idle" if status is None else status)
			self.data_queue.task_done()

		# send a heartbeat which keeps the server thread alive
		self.heartbeat = time()

		if data_server.running:
			return 1/30

		print("CLOSING TIMER")



class StartServer(bpy.types.Operator):
	"""Start the external data server"""
	bl_idname = "geomviz.start_server"
	bl_label = "Start external data server"

	def execute(self, context):
		port = context.scene.geomviz_server_port

		if context.scene.geomviz_collection is None:
			utils.error_popup(context, "No geomviz collection", """
				Select a destination collection for geomviz objects to be added to.""")
			return {'CANCELLED'}

		data_server.start_async(port)

		return {'FINISHED'}


class StopServer(bpy.types.Operator):
	"""Stop the external data server"""
	bl_idname = "geomviz.stop_server"
	bl_label = "Stop external data server"

	def execute(self, context):
		data_server.stop()

		return {'FINISHED'}


# have one server in the global scope
try:
	# if module already loaded, a server instance already exists.
	# stop the old server if necessary
	data_server.stop()
except NameError:
	pass

data_server = DataServer()

