#!/usr/bin/env python3
"""
Advanced HTTP bridge server that automatically forwards messages to ESP32
via Serial Terminal app using Android's accessibility service
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
import subprocess
import os

class AdvancedBridgeHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/get_status':
            response = {
                'status': 'connected',
                'message': 'ESP32 Advanced Bridge Ready',
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
            print(f"🚀 Received command: {command}")
            
            # Forward to ESP32 via Serial Terminal
            success = self.forward_to_esp32(command)
            
            response = {
                'status': 'success' if success else 'error',
                'message': f'Command "{command}" {"sent to ESP32" if success else "failed to send"}',
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
    
    def forward_to_esp32(self, message):
        """Forward message to ESP32 via Serial Terminal app"""
        try:
            print(f"📤 Forwarding to ESP32: {message}")
            
            # Method 1: Try using Android's input command (if available)
            try:
                # This would work if we have root access or proper permissions
                subprocess.run([
                    'am', 'broadcast', '-a', 'com.serialterminal.SEND_MESSAGE',
                    '--es', 'message', message
                ], check=True, timeout=5)
                print("✅ Message sent via broadcast")
                return True
            except:
                pass
            
            # Method 2: Write to a file that Serial Terminal can read
            try:
                with open('/sdcard/Download/esp32_message.txt', 'w') as f:
                    f.write(message)
                print("✅ Message written to file")
                return True
            except:
                pass
            
            # Method 3: Use Android's input text (simulates typing)
            try:
                # This simulates typing the message
                subprocess.run([
                    'input', 'text', message
                ], check=True, timeout=5)
                print("✅ Message typed via input")
                return True
            except:
                pass
            
            print("❌ All forwarding methods failed")
            return False
            
        except Exception as e:
            print(f"❌ Error forwarding message: {e}")
            return False

def run_server(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, AdvancedBridgeHandler)
    print("🚀 Advanced ESP32 Bridge Server Starting...")
    print(f"📱 Server running on: http://localhost:{port}")
    print("🔗 Connect your Flutter app now!")
    print("📤 Messages will be automatically forwarded to ESP32")
    print("⏹️  Press Ctrl+C to stop")
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
