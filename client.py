import socket
import pickle

def send_object(data, port=8888, show_response=True):
    # Create a socket object
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    binary = pickle.dumps(data)

    try:
        # Connect to the server
        client_socket.connect(('127.0.0.1', port))

        # Send data to the server
        client_socket.sendall(binary)

        # Receive data from the server (optional)
        received_data = client_socket.recv(1024)
        if show_response:
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

    data = eval(args.message)

    send_object(data, port=args.port)
