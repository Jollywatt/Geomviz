import socket
import pickle

def send_data_to_server(data, port=8888, show_response=True):
	# Create a socket object
	client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

	binary = pickle.dumps(data)

	try:
		# Connect to the server
		client_socket.connect(('127.0.0.1', port))

		# Send data to the server
		client_socket.sendall(binary)

		# Receive data from the server (optional)
		# received_data = client_socket.recv(1024)
		# if show_response:
			# print(f"Received from server: {received_data.decode('utf-8')}")

	finally:
		# Close the socket
		client_socket.close()

