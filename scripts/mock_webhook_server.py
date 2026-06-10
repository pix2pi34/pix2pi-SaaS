from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        print("===== WEBHOOK POST =====")
        print(f"path={self.path}")
        print(body)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        return

server = HTTPServer(("0.0.0.0", 18081), Handler)
print("mock webhook server listening on :18081")
server.serve_forever()
