/*
 * ESP32 Real Bluetooth SPP for Gemini Bridge
 * 
 * This code sets up ESP32 with Bluetooth SPP for real communication
 * with the Flutter Gemini Bridge app.
 * 
 * Requirements:
 * - ESP32 development board
 * - SSD1306 OLED display (128x64)
 * - Bluetooth enabled
 * 
 * Libraries needed:
 * - BluetoothSerial
 * - Adafruit SSD1306
 * - Adafruit GFX
 */

#include "BluetoothSerial.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// OLED display configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

// Create display object
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Bluetooth Serial object
BluetoothSerial SerialBT;

// State variables
String receivedMessage = "";
unsigned long lastRequestTime = 0;
const unsigned long REQUEST_INTERVAL = 30000; // 30 seconds
int currentCommand = 0;
String commands[] = {"WEATHER?", "TIME?", "DATE?", "HELLO?", "JOKE?", "QUOTE?"};

void setup() {
  Serial.begin(115200);
  
  // Initialize OLED display
  if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;);
  }
  
  // Clear display
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0,0);
  display.println("ESP32 Gemini Bridge");
  display.println("Initializing...");
  display.display();
  delay(2000);
  
  // Initialize Bluetooth
  SerialBT.begin("ESP32_Gemini_Bridge"); // Bluetooth device name
  Serial.println("Bluetooth device is now discoverable as 'ESP32_Gemini_Bridge'");
  
  // Update display
  display.clearDisplay();
  display.setCursor(0,0);
  display.println("ESP32 Ready");
  display.println("BT: ESP32_Gemini_Bridge");
  display.println("Waiting for connection...");
  display.display();
  
  lastRequestTime = millis();
}

void loop() {
  // Check for incoming Bluetooth messages
  if (SerialBT.available()) {
    receivedMessage = SerialBT.readString();
    receivedMessage.trim();
    
    Serial.println("Received: " + receivedMessage);
    
    // Display received message on OLED
    displayMessage("Received:", receivedMessage);
    
    // Send acknowledgment
    SerialBT.println("OK");
  }
  
  // Send periodic requests (every 30 seconds)
  if (millis() - lastRequestTime >= REQUEST_INTERVAL) {
    if (SerialBT.hasClient()) {
      String command = commands[currentCommand];
      SerialBT.println(command);
      Serial.println("Sent: " + command);
      
      // Display sent command on OLED
      displayMessage("Sent:", command);
      
      // Move to next command
      currentCommand = (currentCommand + 1) % (sizeof(commands) / sizeof(commands[0]));
    } else {
      // No client connected, show waiting message
      displayMessage("Status:", "No BT connection");
    }
    
    lastRequestTime = millis();
  }
  
  delay(100);
}

void displayMessage(String label, String message) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  // Display label
  display.setCursor(0, 0);
  display.println(label);
  
  // Display message (truncate if too long)
  display.setCursor(0, 16);
  if (message.length() > 20) {
    display.println(message.substring(0, 17) + "...");
  } else {
    display.println(message);
  }
  
  // Display connection status
  display.setCursor(0, 40);
  if (SerialBT.hasClient()) {
    display.println("BT: Connected");
  } else {
    display.println("BT: Disconnected");
  }
  
  // Display time
  display.setCursor(0, 56);
  display.println("Time: " + String(millis() / 1000) + "s");
  
  display.display();
}

/*
 * Manual Commands (for testing):
 * 
 * You can also send commands manually by opening the Serial Monitor
 * and typing commands. The ESP32 will forward them via Bluetooth.
 */
void serialEvent() {
  while (Serial.available()) {
    String command = Serial.readString();
    command.trim();
    
    if (command.length() > 0) {
      SerialBT.println(command);
      Serial.println("Forwarded: " + command);
      displayMessage("Manual:", command);
    }
  }
}

