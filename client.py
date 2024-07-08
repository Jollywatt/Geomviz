import socket

def send_data_to_server(data, port=8888):
    # Create a socket object
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    try:
        # Connect to the server
        client_socket.connect(('127.0.0.1', port))

        # Send data to the server
        client_socket.sendall(data.encode('utf-8'))

        # Receive data from the server (optional)
        received_data = client_socket.recv(1024)
        print(f"Received from server: {received_data.decode('utf-8')}")

    finally:
        # Close the socket
        client_socket.close()

# Example usage:
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("message")
    parser.add_argument("--port", default=8888, type=int)
    args = parser.parse_args()

    send_data_to_server(args.message, port=args.port)
