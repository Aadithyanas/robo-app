#!/usr/bin/env python3
"""
Super simple HTTP bridge for ESP32
Just run this in Termux - no external files needed!
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time

class BridgeHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/send_command':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            command = data.get('command', '')
            print(f"ESP32 Command: {command}")
            
            response = {
                'status': 'success',
                'message': f'Command "{command}" sent to ESP32',
                'timestamp': time.time()
            }
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())
            
        elif self.path == '/get_status':
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
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

if __name__ == '__main__':
    server = HTTPServer(('', 8080), BridgeHandler)
    print("🚀 ESP32 Bridge Server Starting...")
    print("📱 Server running on: http://localhost:8080")
    print("🔗 Connect your Flutter app now!")
    print("⏹️  Press Ctrl+C to stop")
    server.serve_forever()
