#!/usr/bin/env python3
"""
ESP32 Auto Sender - Reads messages from file and sends to ESP32
This script can be run alongside Serial Terminal to automatically forward messages
"""

import time
import os
import sys

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
    print("🤖 ESP32 Auto Sender Started")
    print("📁 Watching for messages to forward to ESP32...")
    print("⏹️  Press Ctrl+C to stop")
    
    last_message = ""
    
    try:
        while True:
            message, file_path = read_message_file()
            
            if message and message != last_message:
                print(f"🚀 New message detected: {message}")
                print(f"📤 Send this message to ESP32: {message}")
                print("💡 Copy and paste this message in Serial Terminal app")
                print("=" * 50)
                
                # Delete the file so we don't repeat the same message
                if file_path:
                    delete_message_file(file_path)
                
                last_message = message
            
            time.sleep(1)  # Check every second
            
    except KeyboardInterrupt:
        print("\n⏹️  ESP32 Auto Sender stopped")

if __name__ == '__main__':
    main()
