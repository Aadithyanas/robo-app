#!/usr/bin/env python3
"""
Auto Serial Sender - Automatically sends messages to Serial Terminal app
Uses Android's accessibility service to automate the process
"""

import time
import os
import subprocess
import json

def send_to_serial_terminal(message):
    """Automatically send message to Serial Terminal app"""
    try:
        print(f"🚀 Auto-sending to Serial Terminal: {message}")
        
        # Method 1: Try using Android's input command
        try:
            # This simulates typing the message
            subprocess.run([
                'input', 'text', message
            ], check=True, timeout=5)
            print("✅ Message sent via input command")
            return True
        except Exception as e:
            print(f"❌ Input command failed: {e}")
        
        # Method 2: Try using Android's am broadcast
        try:
            subprocess.run([
                'am', 'broadcast', '-a', 'com.serialterminal.SEND_MESSAGE',
                '--es', 'message', message
            ], check=True, timeout=5)
            print("✅ Message sent via broadcast")
            return True
        except Exception as e:
            print(f"❌ Broadcast failed: {e}")
        
        # Method 3: Try using Android's service call
        try:
            subprocess.run([
                'service', 'call', 'input', '1', 's16', message
            ], check=True, timeout=5)
            print("✅ Message sent via service call")
            return True
        except Exception as e:
            print(f"❌ Service call failed: {e}")
        
        print("❌ All automatic methods failed")
        return False
        
    except Exception as e:
        print(f"❌ Error sending message: {e}")
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
    print("🤖 Auto Serial Sender Started")
    print("📁 Watching for messages to auto-send to Serial Terminal...")
    print("⏹️  Press Ctrl+C to stop")
    
    last_message = ""
    
    try:
        while True:
            message, file_path = read_message_file()
            
            if message and message != last_message:
                print(f"🚀 New message detected: {message}")
                
                # Try to automatically send to Serial Terminal
                success = send_to_serial_terminal(message)
                
                if success:
                    print("✅ Message automatically sent to Serial Terminal!")
                else:
                    print("❌ Auto-send failed - manual copy-paste required")
                    print(f"📤 Manual: Copy this message to Serial Terminal: {message}")
                
                print("=" * 50)
                
                # Delete the file so we don't repeat the same message
                if file_path:
                    delete_message_file(file_path)
                
                last_message = message
            
            time.sleep(1)  # Check every second
            
    except KeyboardInterrupt:
        print("\n⏹️  Auto Serial Sender stopped")

if __name__ == '__main__':
    main()
