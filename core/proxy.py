import socket, threading, select

LISTENING_PORT = 80
SSH_PORT = 109
BUFFER_SIZE = 8192
SOCKET_TIMEOUT = 30  # seconds per select() wait

# Backend routing map (path -> xray inbound port)
ROUTES = {
    "/vmess": 10002,
    "/vless": 10001,
    "/trojan-ws": 10003,
    "/trojan-notls": 10006,
}


def handle_client(client_socket, addr):
    server_socket = None
    try:
        client_socket.settimeout(SOCKET_TIMEOUT)
        request = client_socket.recv(BUFFER_SIZE).decode('utf-8', errors='ignore')
        if not request:
            return

        request_clean = request.lower().replace(" ", "")
        if "upgrade:websocket" not in request_clean:
            client_socket.send(b"HTTP/1.1 200 OK\r\n\r\n")
            return

        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.settimeout(SOCKET_TIMEOUT)

        target_port = None
        for path, port in ROUTES.items():
            if path in request_clean:
                target_port = port
                break

        if target_port is None:
            # Default: route to SSH (need to fake the WS handshake for the injector)
            target_port = SSH_PORT
            server_socket.connect(('127.0.0.1', target_port))
            response = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
            client_socket.send(response.encode('utf-8'))
        else:
            server_socket.connect(('127.0.0.1', target_port))
            server_socket.send(request.encode('utf-8'))

        # Bidirectional forwarding loop with timeout so a dead peer can't wedge us.
        while True:
            r, _, _ = select.select([client_socket, server_socket], [], [], SOCKET_TIMEOUT)
            if not r:
                break
            for sock in r:
                try:
                    data = sock.recv(BUFFER_SIZE)
                except (socket.timeout, ConnectionResetError):
                    return
                except Exception:
                    return
                if not data:
                    return
                dest = server_socket if sock is client_socket else client_socket
                try:
                    dest.sendall(data)
                except Exception:
                    return
    except Exception as e:
        # Never let one bad connection take the service down.
        print(f"[proxy] error handling {addr}: {e}", flush=True)
    finally:
        try:
            client_socket.close()
        except Exception:
            pass
        if server_socket:
            try:
                server_socket.close()
            except Exception:
                pass


def start_server():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', LISTENING_PORT))
    server.listen(128)
    print(f"[proxy] listening on 0.0.0.0:{LISTENING_PORT}", flush=True)
    while True:
        try:
            client_sock, addr = server.accept()
        except Exception as e:
            print(f"[proxy] accept error: {e}", flush=True)
            continue
        threading.Thread(target=handle_client, args=(client_sock, addr), daemon=True).start()


if __name__ == "__main__":
    start_server()
