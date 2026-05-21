import http.server
import urllib.request
import urllib.error

class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress standard logging to keep console clean
        pass

    def do_GET(self):
        self.proxy_request('GET')

    def do_POST(self):
        self.proxy_request('POST')

    def do_PUT(self):
        self.proxy_request('PUT')

    def do_DELETE(self):
        self.proxy_request('DELETE')

    def proxy_request(self, method):
        url = f"https://connectthrive.in{self.path}"
        
        # Read request body if present
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else None
        
        # Construct headers
        headers = {}
        for key, val in self.headers.items():
            if key.lower() not in ['host', 'connection']:
                headers[key] = val
        headers['Host'] = 'connectthrive.in'
        
        req = urllib.request.Request(url, data=body, headers=headers, method=method)
        
        try:
            with urllib.request.urlopen(req) as response:
                self.send_response(response.status)
                for key, val in response.headers.items():
                    if key.lower() not in ['transfer-encoding', 'connection', 'content-length']:
                        self.send_header(key, val)
                self.end_headers()
                self.wfile.write(response.read())
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            for key, val in e.headers.items():
                if key.lower() not in ['transfer-encoding', 'connection', 'content-length']:
                    self.send_header(key, val)
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode('utf-8'))

def run():
    server_address = ('', 8082)
    httpd = http.server.HTTPServer(server_address, ProxyHandler)
    print("Host proxy running on port 8082...")
    httpd.serve_forever()

if __name__ == '__main__':
    run()
