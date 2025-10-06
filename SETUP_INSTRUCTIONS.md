# ESP32 Eye Robot with Bluetooth and Gemini AI Integration

This project combines an ESP32-based eye robot with Bluetooth connectivity and Gemini AI integration through a Flutter mobile app.

## Hardware Requirements

### ESP32 Setup
- ESP32 development board
- SSD1306 OLED display (128x64)
- TTP223 touch sensor (optional)
- Jumper wires
- Breadboard

### Wiring Diagram
```
ESP32 Pin    Component
--------     ---------
3.3V    ->   OLED VCC
GND     ->   OLED GND
GPIO21  ->   OLED SDA
GPIO22  ->   OLED SCL
GPIO2   ->   TTP223 Touch Sensor (optional)
```

## Software Setup

### 1. Arduino IDE Setup

1. Install Arduino IDE
2. Install ESP32 board support:
   - Go to File > Preferences
   - Add this URL to Additional Board Manager URLs:
     `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - Go to Tools > Board > Boards Manager
   - Search for "ESP32" and install "ESP32 by Espressif Systems"

3. Install required libraries:
   - Adafruit SSD1306
   - Adafruit GFX Library
   - BluetoothSerial (included with ESP32)

### 2. Flutter App Setup

1. Install Flutter SDK
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. For Android:
   - Add Bluetooth permissions to `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <uses-permission android:name="android.permission.BLUETOOTH" />
     <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
     <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
     ```

4. For iOS:
   - Add Bluetooth permissions to `ios/Runner/Info.plist`:
     ```xml
     <key>NSBluetoothAlwaysUsageDescription</key>
     <string>This app needs Bluetooth to communicate with ESP32</string>
     ```

## Usage Instructions

### 1. Upload Arduino Code

1. Open `esp32_eye_robot_bluetooth.ino` in Arduino IDE
2. Select your ESP32 board and COM port
3. Upload the code to your ESP32

### 2. Run Flutter App

1. Connect your Android/iOS device or run on emulator
2. Run the Flutter app:
   ```bash
   flutter run
   ```

### 3. Connect to ESP32

1. Turn on Bluetooth on your mobile device
2. In the Flutter app, tap "Scan for Devices"
3. Look for "ESP32_Eye_Robot" in the device list
4. Tap to connect

### 4. Control the Eye Robot

Once connected, you can:
- Send animation commands (A0-A9) to trigger different eye animations
- Use the touch sensor on the ESP32 to trigger heart eyes animation
- Send text messages that will be processed by Gemini AI

## Available Commands

### Animation Commands
- `A0` - Wake up animation
- `A1` - Center eyes
- `A2` - Move right big eye
- `A3` - Move left big eye
- `A4` - Blink (slow)
- `A5` - Blink (fast)
- `A6` - Happy eyes
- `A7` - Sleep
- `A8` - Random saccade movements
- `A9` - Melt eyes

### Other Commands
- `CONNECT` - Acknowledge connection
- `PING` - Test connection (responds with PONG)
- Any text message - Will be processed by Gemini AI

## Features

### ESP32 Features
- Real-time eye animations on OLED display
- Bluetooth SPP communication
- Touch sensor for heart eyes animation
- Connection status display
- Serial command interface

### Flutter App Features
- Bluetooth device scanning and connection
- Real-time communication with ESP32
- Gemini AI integration for intelligent responses
- Cross-platform support (Android/iOS)
- Desktop mock mode for testing

## Troubleshooting

### ESP32 Issues
- **OLED not displaying**: Check wiring and I2C address (0x3C)
- **Bluetooth not discoverable**: Ensure Bluetooth is enabled and device name is correct
- **Touch sensor not working**: Check GPIO2 connection

### Flutter App Issues
- **Bluetooth permission denied**: Check app permissions in device settings
- **Device not found**: Ensure ESP32 is powered on and Bluetooth is enabled
- **Connection failed**: Try disconnecting and reconnecting

### Common Solutions
1. Restart both ESP32 and mobile device
2. Clear Bluetooth cache on mobile device
3. Check that both devices are within range
4. Verify all wiring connections

## Development

### Adding New Animations
1. Add new animation function in Arduino code
2. Add case in `launch_animation_with_index()` function
3. Update `max_animation_index` if needed

### Customizing Bluetooth Communication
1. Modify message handling in `handle_bluetooth_command()`
2. Add new command types as needed
3. Update Flutter app to send new commands

## License

This project is open source and available under the MIT License.

