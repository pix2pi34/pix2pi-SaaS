from http.server import BaseHTTPRequestHandler, HTTPServer

LOG_FILE = "/tmp/mock_webhook_57p.log"

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write("===== WEBHOOK POST =====\n")
            f.write(f"path={self.path}\n")
            f.write(body + "\n")
        print("WEBHOOK ALINDI")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, format, *args):
        return

server = HTTPServer(("0.0.0.0", 18081), Handler)
print("mock webhook server listening on :18081")
server.serve_forever()
