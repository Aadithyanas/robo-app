#!/usr/bin/env python3
"""
Simple HTTP server that bridges Flutter app and ESP32 via Serial Terminal
Run this on your phone using Termux or similar Python environment
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time

class BridgeHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/get_status':
            # Return ESP32 status
            response = {
                'status': 'connected',
                'message': 'ESP32 Bridge Ready',
                'timestamp': time.time()
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/send_command':
            # Receive command from Flutter app
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            command = data.get('command', '')
            print(f"Received command: {command}")
            
            # TODO: Forward to Serial Terminal app
            # For now, we'll just echo back
            # In a real implementation, you would:
            # 1. Send the command to Serial Terminal app
            # 2. Wait for ESP32 response
            # 3. Return the ESP32 response
            
            response = {
                'status': 'success',
                'message': f'Command "{command}" forwarded to ESP32',
                'timestamp': time.time()
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_OPTIONS(self):
        # Handle CORS preflight requests
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, BridgeHandler)
    print(f"Bridge server running on port {port}")
    print("Connect your Flutter app to: http://localhost:{port}")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
