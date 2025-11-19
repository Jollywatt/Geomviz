import bpy
import threading
import socket
import pickle
import queue
from time import time

from . import rigs
from . import scene
from . import utils

class ServerStatus:
	def __init__(self, message, icon):
		self.message = message
		self.icon = icon

def validate_data(binary):
	try:
		data = pickle.loads(binary)
	except Exception as e:
		raise utils.InvalidDataException(e)
	else:
		if isinstance(data, dict):
			if 'objects' in data:
				for rig in data['objects']:
					if isinstance(rig, dict):
						pass
					else:
						raise utils.InvalidDataException(f"Rig data is not a dictionary: {rig!r}.")
			else:
				raise utils.InvalidDataException(f"Data is missing 'objects' key: {data!r}.")
		else:
			raise utils.InvalidDataException(f"Data is of unexpected type {type(data)}.")

		return data

class DataServer():
	running = False
	port = None
	panel_area = None
	status = "Idle"
	status_icon = 'RADIOBUT_OFF'
	data_queue = queue.Queue()
	heartbeat = 0.
	queue_check_delay = 1/30 # pause between checks for incoming data

	def set_status(self, status, icon):
		self.status = status
		self.status_icon = icon
		print(f"DataServer status: {status}")
		if bpy.context.screen != None:
			for area in bpy.context.screen.areas:
				if area.ui_type == 'PROPERTIES':
					area.tag_redraw()

	def start(self, port):
		self.port = port

		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

			try:
				sock.bind(('127.0.0.1', self.port))
			except OSError as e:
				self.set_status(f"Error: {e}", 'ERROR')
				return

			sock.settimeout(1)
			sock.listen()

			self.running = True
			self.set_status(f"Listening on port {self.port}...", 'RADIOBUT_ON')

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
			self.set_status("Idle", 'RADIOBUT_OFF')
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

		conn.settimeout(1)
		binary = b""
		while True:
			try:
				packet = conn.recv(1 << 12)
				if not packet: break
				binary += packet
			except socket.timeout:
				print("Connection timed out.")
				break

		try:
			conn.send(f"Received {len(binary)} bytes.".encode())
			self.data_queue.put(binary)
		finally:
			conn.close()

	def read_from_queue(self):
		# this runs as a registered bpy.app timer
		# reading data left by the server's thread in the shared queue
		while not self.data_queue.empty():
			binary = self.data_queue.get()
			try:
				data = validate_data(binary)
				status = scene.handle_scene_data(data)
				self.set_status(status, 'RADIOBUT_ON')
			except utils.GeomvizError as e:
				self.set_status(e.message, e.icon)
			else:
				self.data_queue.task_done()

		# send a heartbeat which keeps the server thread alive
		self.heartbeat = time()

		if data_server.running:
			return self.queue_check_delay

		print("CLOSING TIMER")



class StartServer(bpy.types.Operator):
	"""Start a local server to listen for data from other processes"""
	bl_idname = "geomviz.start_server"
	bl_label = "Start listening"

	@classmethod
	def poll(self, context):
		enabled = context.scene.geomviz_collection is not None
		if not enabled:
			self.poll_message_set("Select a destination collection first.")
		return enabled

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
	bl_label = "Stop listening"

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

