# Bluetooth Connection Test Guide

## Testing the ESP32 Eye Robot with Bluetooth

### Step 1: Hardware Setup
1. Connect ESP32 to OLED display:
   - ESP32 3.3V → OLED VCC
   - ESP32 GND → OLED GND  
   - ESP32 GPIO21 → OLED SDA
   - ESP32 GPIO22 → OLED SCL
2. Connect TTP223 touch sensor (optional):
   - ESP32 GPIO2 → TTP223 Signal
   - ESP32 3.3V → TTP223 VCC
   - ESP32 GND → TTP223 GND

### Step 2: Upload Arduino Code
1. Open `esp32_eye_robot_bluetooth.ino` in Arduino IDE
2. Select ESP32 board and correct COM port
3. Upload the code
4. Open Serial Monitor (115200 baud) to see debug messages

### Step 3: Test ESP32 Functionality
1. **Power On Test**: ESP32 should show "Eye Robot BT" on OLED
2. **Bluetooth Test**: OLED should show "BT: Disconnected" initially
3. **Touch Test**: Touch the sensor to trigger heart eyes animation
4. **Serial Test**: Send "A0" through Serial Monitor to test wakeup animation

### Step 4: Test Flutter App
1. Run `flutter run` on Android device
2. Grant Bluetooth permissions when prompted
3. Tap "Scan for Devices"
4. Look for "ESP32_Eye_Robot" in the device list
5. Tap to connect

### Step 5: Test Communication
1. **Connection Test**: ESP32 OLED should show "BT: Connected"
2. **Animation Test**: Send "A1" through Flutter app to center eyes
3. **Heart Test**: Touch ESP32 sensor to trigger heart animation
4. **AI Test**: Send any text message to test Gemini integration

### Expected Results
- ESP32 OLED displays connection status
- Eye animations respond to commands
- Touch sensor triggers heart eyes
- Flutter app shows connection status
- Messages are exchanged successfully

### Troubleshooting
- **No devices found**: Check ESP32 is powered and Bluetooth enabled
- **Connection failed**: Try restarting both devices
- **Animations not working**: Check OLED wiring and I2C address
- **Touch not working**: Check GPIO2 connection

### Commands Reference
- `A0` - Wake up
- `A1` - Center eyes  
- `A2` - Move right big eye
- `A3` - Move left big eye
- `A4` - Blink slow
- `A5` - Blink fast
- `A6` - Happy eyes
- `A7` - Sleep
- `A8` - Random movements
- `A9` - Melt eyes
- Touch sensor - Heart eyes animation

