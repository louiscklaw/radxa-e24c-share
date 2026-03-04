import http.server
import socketserver
import urllib.request

PORT = 8888
BIND_ADDRESS = "0.0.0.0"

class ForwardProxy(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # In a forward proxy, self.path is the full URL (e.g., http://google.com)
        url = self.path
        print(f"Proxying request for: {url}")

        try:
            # Create the request and copy browser headers (optional, but better for compatibility)
            req = urllib.request.Request(url, headers=self.headers)
            with urllib.request.urlopen(req) as response:
                self.send_response(response.status)

                # Forward all response headers back to Chrome
                for header, value in response.getheaders():
                    self.send_header(header, value)
                self.end_headers()

                # Stream the content back to the browser
                self.wfile.write(response.read())
        except Exception as e:
            self.send_error(500, f"Proxy Error: {e}")

# Allow the server to restart immediately without 'Address already in use' errors
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer((BIND_ADDRESS, PORT), ForwardProxy) as httpd:
    print(f"Forward Proxy started on port {PORT}. Configure Chrome to use localhost:{PORT}")
    httpd.serve_forever()
