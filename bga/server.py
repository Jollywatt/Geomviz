import bpy
import threading
import socket

lock = threading.Lock()


class DataServer():
	running = False
	port = None
	data = None
	panel_area = None

	def start(self, operator, port=8888):
		self.port = port

		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.settimeout(1)
		try:
			sock.bind(('127.0.0.1', self.port))
		except OSError as e:
			operator.report({'ERROR'}, e)
			return

		sock.listen()
		self.running = True
		print(f"Listening on port {self.port}...")

		while self.running:
			try:
				conn, addr = sock.accept()
			except socket.timeout:
				pass
			except:
				raise
			else:
				self.handle_client(conn, addr)

		print(f"No longer listening on port {self.port}.")

	def stop(self):
		self.running = False

	def handle_client(self, conn, addr):
		data = conn.recv(1024).decode('utf-8')
		print(f"Received data {data} from {addr}.")

		with lock:
			self.data = data

		conn.send("Received.".encode())
		conn.close()

		self.trigger_update()

	def trigger_update(self):
		if type(self.panel_area) is bpy.types.Area:
			self.panel_area.tag_redraw()


data_server = DataServer()


class StartServer(bpy.types.Operator):
	"""Start the external data server"""
	bl_idname = "ga.start_server"
	bl_label = "Start external data server"

	def execute(self, context):

		port = context.scene.ga_server_port
		thread = threading.Thread(target=data_server.start, args=(self, port))
		thread.start()

		return {'FINISHED'}


class StopServer(bpy.types.Operator):
	"""Stop the external data server"""
	bl_idname = "ga.stop_server"
	bl_label = "Stop external data server"

	def execute(self, context):

		data_server.stop()

		return {'FINISHED'}