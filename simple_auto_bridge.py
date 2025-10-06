#!/usr/bin/env python3
"""
Simple automatic bridge that writes messages to a file
Serial Terminal can read this file and send to ESP32
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
import os

class AutoBridgeHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/get_status':
            response = {
                'status': 'connected',
                'message': 'ESP32 Auto Bridge Ready',
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
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            command = data.get('command', '')
            print(f"🚀 Received: {command}")
            
            # Write message to file for Serial Terminal to read
            success = self.write_message_to_file(command)
            
            response = {
                'status': 'success' if success else 'error',
                'message': f'Message {"saved" if success else "failed to save"}',
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
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def write_message_to_file(self, message):
        """Write message to a file that can be read by Serial Terminal"""
        try:
            # Try multiple possible paths
            paths = [
                '/sdcard/Download/esp32_message.txt',
                '/sdcard/esp32_message.txt',
                './esp32_message.txt',
                'esp32_message.txt'
            ]
            
            for path in paths:
                try:
                    with open(path, 'w') as f:
                        f.write(message)
                    print(f"✅ Message written to: {path}")
                    return True
                except:
                    continue
            
            print("❌ Could not write to any file path")
            return False
            
        except Exception as e:
            print(f"❌ Error writing message: {e}")
            return False

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, AutoBridgeHandler)
    print("🚀 ESP32 Auto Bridge Server Starting...")
    print(f"📱 Server running on: http://localhost:{port}")
    print("🔗 Connect your Flutter app now!")
    print("📁 Messages will be saved to: esp32_message.txt")
    print("📤 Serial Terminal can read this file and send to ESP32")
    print("⏹️  Press Ctrl+C to stop")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
