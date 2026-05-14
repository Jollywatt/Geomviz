using Sockets

# Connect to the server
sock = connect("127.0.0.1", 8888)

# Send data
message = "hello from julia"
println("Sending: $message")
write(sock, message * "\n")

# Wait for reply
reply = readline(sock)
println("Received: $reply") # readline() strips the newline

# Close connection
close(sock)
