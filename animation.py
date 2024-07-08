import time
import socket
from math import sin, cos

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
        # print(f"Received from server: {received_data.decode('utf-8')}")
        print(".", end="", flush=True)

    finally:
        # Close the socket
        client_socket.close()


def frame(t):
    t *= 2
    r = 0.1*sin(t/2)

    a = (r*cos(3*t), r*sin(3*t), sin(t/2))

    return {
        "Simple Point": [
            (cos(t), sin(t), 0),
            a,
        ],
        "Arrow Vector": [
            a,
        ]
    }

def main(fps=10, port=8888):

    t = time.time()

    while True:
        next_frame = t + 1/fps
        send_data_to_server(repr(frame(t)))
        t = time.time()
        time.sleep(max(0, next_frame - t))

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("--fps", default=10, type=int)
    parser.add_argument("--port", default=8888, type=int)
    args = parser.parse_args()

    main(fps=args.fps, port=args.port)