#!/usr/bin/env python3
"""
Direct ESP32 Sender - Sends messages directly to ESP32 via Bluetooth
Bypasses Serial Terminal app completely
"""

import time
import os
import subprocess
import bluetooth

def find_esp32_device():
    """Find ESP32 device by name"""
    try:
        print("🔍 Scanning for ESP32 device...")
        nearby_devices = bluetooth.discover_devices(lookup_names=True)
        
        for addr, name in nearby_devices:
            if "ESP32_Eye_Robot" in name:
                print(f"✅ Found ESP32: {name} ({addr})")
                return addr
        
        print("❌ ESP32 device not found")
        return None
    except Exception as e:
        print(f"❌ Error scanning for devices: {e}")
        return None

def send_to_esp32(message, device_addr):
    """Send message directly to ESP32 via Bluetooth"""
    try:
        print(f"📤 Sending to ESP32: {message}")
        
        # Create Bluetooth socket
        sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
        sock.connect((device_addr, 1))  # Channel 1 for SPP
        
        # Send message
        sock.send(message.encode())
        
        # Close socket
        sock.close()
        
        print("✅ Message sent successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Error sending to ESP32: {e}")
        return False

def read_message_file():
    """Read the latest message from the file"""
    possible_paths = [
        '/sdcard/Download/esp32_message.txt',
        '/sdcard/esp32_message.txt',
        './esp32_message.txt',
        'esp32_message.txt'
    ]
    
    for path in possible_paths:
        try:
            if os.path.exists(path):
                with open(path, 'r') as f:
                    message = f.read().strip()
                if message:
                    print(f"📖 Read message from {path}: {message}")
                    return message, path
        except:
            continue
    
    return None, None

def delete_message_file(file_path):
    """Delete the message file after reading"""
    try:
        os.remove(file_path)
        print(f"🗑️  Deleted message file: {file_path}")
    except:
        pass

def main():
    print("🤖 Direct ESP32 Sender Started")
    print("📁 Watching for messages to send directly to ESP32...")
    print("⏹️  Press Ctrl+C to stop")
    
    # Find ESP32 device
    esp32_addr = find_esp32_device()
    if not esp32_addr:
        print("❌ Cannot find ESP32 device. Make sure it's discoverable.")
        return
    
    last_message = ""
    
    try:
        while True:
            message, file_path = read_message_file()
            
            if message and message != last_message:
                print(f"🚀 New message detected: {message}")
                
                # Send directly to ESP32
                success = send_to_esp32(message, esp32_addr)
                
                if success:
                    print("✅ Message sent directly to ESP32!")
                else:
                    print("❌ Failed to send to ESP32")
                
                print("=" * 50)
                
                # Delete the file so we don't repeat the same message
                if file_path:
                    delete_message_file(file_path)
                
                last_message = message
            
            time.sleep(1)  # Check every second
            
    except KeyboardInterrupt:
        print("\n⏹️  Direct ESP32 Sender stopped")

if __name__ == '__main__':
    main()
