# ESP32 ↔ Gemini Bridge

A Flutter app that bridges ESP32 devices and Google's Gemini API via Bluetooth Serial (SPP). The ESP32 sends requests like "WEATHER?" or "TIME?" via Bluetooth, and the Flutter app forwards these to Gemini API, then sends the simplified response back to the ESP32 for display on a tiny OLED.

## 🚀 Features

- **Bluetooth Communication**: Scan and connect to ESP32 devices over Bluetooth SPP
- **AI Integration**: Forward ESP32 requests to Google's Gemini API
- **Response Optimization**: Simplify AI responses for small OLED displays (max ~20 characters)
- **Real-time Debugging**: Monitor connection status, requests, and responses
- **Test Interface**: Manual testing of both Bluetooth and Gemini API

## 📱 Supported ESP32 Commands

- `WEATHER?` - Get current weather information
- `TIME?` - Get current time
- `DATE?` - Get today's date
- `HELLO?` - Get a friendly greeting
- `JOKE?` - Get a short joke
- `QUOTE?` - Get an inspirational quote
- `HELP?` - List available commands

## 🛠️ Setup Instructions

### Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **Android Studio** or VS Code with Flutter extension
3. **Android device** with Bluetooth support
4. **ESP32 device** with Bluetooth SPP capability
5. **Google Gemini API key**

### Installation

1. **Clone or download this project**
   ```bash
   git clone <repository-url>
   cd esp32-gemini-bridge
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Get a Gemini API key**
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key for use in the app

4. **Run the app**
   ```bash
   flutter run
   ```

### ESP32 Setup

Your ESP32 should be programmed to:
- Enable Bluetooth SPP (Serial Port Profile)
- Send text commands like "WEATHER?" via Bluetooth
- Display received responses on an OLED screen
- Handle the simplified responses (max 20 characters)

Example ESP32 Arduino code structure:
```cpp
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

void setup() {
  SerialBT.begin("ESP32_Device"); // Device name
  // Initialize OLED display
}

void loop() {
  if (SerialBT.available()) {
    String response = SerialBT.readString();
    // Display response on OLED
  }
  
  // Send periodic requests
  SerialBT.println("WEATHER?");
  delay(30000); // Wait 30 seconds
}
```

## 🔧 Configuration

### API Key Setup
1. Open the app
2. Enter your Gemini API key in the "API Configuration" section
3. Tap "Set API Key"
4. The app will confirm when the key is set

### Bluetooth Connection
1. Ensure your ESP32 is powered on and Bluetooth is enabled
2. Tap "Scan for ESP32" to find available devices
3. Select your ESP32 device from the list
4. Tap "Connect" to establish the connection

## 📱 App Interface

### Main Sections

1. **API Configuration**: Set your Gemini API key
2. **Connection Status**: Shows current Bluetooth connection state
3. **Bluetooth Controls**: Scan for devices and manage connections
4. **Message Exchange**: Displays ESP32 requests and Gemini responses
5. **Test Controls**: Manual testing of Gemini API and ESP32 communication
6. **Available Commands**: Reference for ESP32 command formats

### Status Indicators

- 🔴 **Red**: Not connected or error
- 🟠 **Orange**: Scanning or connecting
- 🟢 **Green**: Connected and ready
- 🔵 **Blue**: Processing request

## 🔍 Troubleshooting

### Common Issues

1. **"Bluetooth not available"**
   - Ensure Bluetooth is enabled on your Android device
   - Check that the app has Bluetooth permissions

2. **"No ESP32 devices found"**
   - Make sure your ESP32 is powered on and Bluetooth is enabled
   - Try restarting the scan
   - Check that ESP32 is advertising with "ESP32" in the name

3. **"API key not set"**
   - Enter a valid Gemini API key in the configuration section
   - Ensure the key has proper permissions for the Gemini API

4. **"Connection failed"**
   - Try disconnecting and reconnecting
   - Restart both the app and ESP32
   - Check that no other device is connected to the ESP32

5. **"Processing failed"**
   - Verify your API key is correct
   - Check your internet connection
   - Ensure you have sufficient API quota

### Debug Information

The app provides detailed status messages in the "Connection Status" section. These messages help identify issues with:
- Bluetooth initialization
- Device scanning
- Connection establishment
- Message processing
- API communication

## 📚 Technical Details

### Architecture

- **BluetoothService**: Handles all Bluetooth communication
- **GeminiService**: Manages API calls to Google Gemini
- **BridgeController**: Orchestrates message flow between ESP32 and Gemini
- **Main UI**: Provides debugging interface and controls

### Message Flow

1. ESP32 sends request via Bluetooth SPP
2. Flutter app receives request through BluetoothService
3. BridgeController processes the request
4. GeminiService calls Google's Gemini API
5. Response is simplified for OLED display
6. Simplified response is sent back to ESP32
7. ESP32 displays response on OLED screen

### Response Optimization

The app automatically optimizes Gemini responses for small OLED displays:
- Removes unnecessary words
- Truncates to ~20 characters
- Converts to uppercase for better readability
- Adds ellipsis for truncated responses

## 🔒 Security Notes

- API keys are stored locally on the device
- No sensitive data is transmitted to ESP32
- ESP32 only receives simplified, safe responses
- All communication is local Bluetooth (no internet required for ESP32)

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the debug messages in the app
3. Ensure all prerequisites are met
4. Check that your ESP32 is properly configured

---

**Happy bridging! 🚀**
