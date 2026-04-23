import socket, threading, select

LISTENING_PORT = 8880
SSH_PORT = 109
RESPONSE = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: foo\r\n\r\n"

def handle_client(client_socket):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        # Read the junk payload to clear the buffer
        client_socket.recv(4096)
        # Connect directly to Dropbear
        server_socket.connect(('127.0.0.1', SSH_PORT))
        # Blindly send the magic 101 response
        client_socket.sendall(RESPONSE)
        
        while True:
            r, w, x = select.select([client_socket, server_socket], [], [])
            if client_socket in r:
                data = client_socket.recv(4096)
                if not data: break
                server_socket.send(data)
            if server_socket in r:
                data = server_socket.recv(4096)
                if not data: break
                client_socket.send(data)
    except:
        pass
    finally:
        client_socket.close()
        server_socket.close()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', LISTENING_PORT))
    server.listen(100)
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client,)).start()

if __name__ == "__main__":
    start_server()