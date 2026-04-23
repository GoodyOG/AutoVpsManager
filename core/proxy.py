import socket, threading, select, sys

LISTENING_PORT = 80
SSH_PORT = 109

def handle_client(client_socket):
    server_socket = None
    try:
        # Read the incoming HTTP payload
        request = client_socket.recv(4096).decode('utf-8', errors='ignore')
        
        # Convert to lowercase AND strip all spaces for bulletproof matching
        request_clean = request.lower().replace(" ", "")
        
        # Now it catches ANY capitalization and ANY weird spacing
        if "upgrade:websocket" in request_clean:
            server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            
            # --- THE SMART ROUTER ---
            if "/vmess" in request_clean:
                server_socket.connect(('127.0.0.1', 10002))
                server_socket.send(request.encode('utf-8'))
            elif "/vless" in request_clean:
                server_socket.connect(('127.0.0.1', 10001))
                server_socket.send(request.encode('utf-8'))
            elif "/trojan-ws" in request_clean:
                server_socket.connect(('127.0.0.1', 10003))
                server_socket.send(request.encode('utf-8'))
            else:
                # Default: Route to SSH
                server_socket.connect(('127.0.0.1', SSH_PORT))
                # SSH needs us to fake the handshake
                response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
                client_socket.send(response.encode('utf-8'))

            # --- FORWARDING LOOP ---
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
        else:
            client_socket.send(b"HTTP/1.1 200 OK\r\n\r\n")
    except Exception as e:
        pass
    finally:
        client_socket.close()
        # THE FIX: Kill the zombie socket to free RAM instantly
        if server_socket:
            server_socket.close()

def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', LISTENING_PORT))
    server.listen(100)
    while True:
        client_sock, addr = server.accept()
        threading.Thread(target=handle_client, args=(client_sock,)).start()

if __name__ == "__main__":
    start_server()