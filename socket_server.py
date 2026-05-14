import socket

# Create a server socket
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", 8888))
server.listen(1)

print("Server listening on 127.0.0.1:8888")

try:
    while True:
        # Accept connection
        conn, addr = server.accept()
        print(f"Connected by {addr}")
        
        # Receive data (read until newline)
        data = conn.recv(1024).decode().strip()
        print(f"Received: {data}")
        
        # Transform to uppercase
        response = data.upper()
        print(f"Sending: {response}")
        
        # Send response
        conn.send((response + "\n").encode())
        
        # Close connection
        conn.close()
except KeyboardInterrupt:
    print("\nShutting down server")
finally:
    server.close()
