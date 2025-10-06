#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "BluetoothSerial.h"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define TOUCH_SENSOR_PIN 2

BluetoothSerial SerialBT;

bool bt_connected = false;
unsigned long last_check = 0;
String device_name = "ESP32_Eye_Robot";  // Changed to match Flutter app expectations

void display_msg(String l1, String l2 = "", String l3 = "", String l4 = "") {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    
    display.setCursor(0, 0);
    display.println(l1);
    if (l2.length() > 0) { display.setCursor(0, 16); display.println(l2); }
    if (l3.length() > 0) { display.setCursor(0, 32); display.println(l3); }
    if (l4.length() > 0) { display.setCursor(0, 48); display.println(l4); }
    
    display.display();
}

void setup() {
    Serial.begin(115200);
    delay(500);
    
    Serial.println("\n\n=================================");
    Serial.println("ESP32 Eye Robot Bluetooth");
    Serial.println("=================================");
    
    // Init display
    if(!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
        Serial.println("Display init failed!");
        while(1);
    }
    
    pinMode(TOUCH_SENSOR_PIN, INPUT);
    
    display_msg("ESP32 Eye Robot", "Bluetooth", "Initializing...");
    delay(1500);
    
    // Start Bluetooth
    Serial.println("Starting Bluetooth...");
    
    if (!SerialBT.begin(device_name)) {
        Serial.println("Bluetooth FAILED!");
        display_msg("ERROR!", "BT Init Failed", "Check ESP32");
        while(1) delay(1000);
    }
    
    Serial.println("SUCCESS! BT Started");
    Serial.println("Device: " + device_name);
    Serial.println("=================================\n");
    
    display_msg("BT STARTED!", "", "Name: " + device_name, "Ready!");
    delay(2000);
    
    display_msg("WAITING...", "", "Connect via", "Serial Terminal");
    
    Serial.println("Waiting for connection...");
}

void loop() {
    // Check connection every 500ms
    if (millis() - last_check > 500) {
        last_check = millis();
        
        bool is_connected = SerialBT.hasClient();
        
        // Connection state changed
        if (is_connected != bt_connected) {
            bt_connected = is_connected;
            
            if (bt_connected) {
                Serial.println("\n>>> CONNECTED! <<<\n");
                
                // Send welcome messages
                SerialBT.println("CONNECTED");
                delay(100);
                SerialBT.println("ESP32_Eye_Robot Ready");
                delay(100);
                
                display_msg("CONNECTED!", "", "Ready for", "commands");
                
            } else {
                Serial.println("\n>>> DISCONNECTED <<<\n");
                display_msg("Disconnected", "", "Waiting for", "connection...");
                delay(1000);
            }
        }
        
        // Update display when connected
        if (bt_connected) {
            display_msg("ONLINE", "", "Connected OK", "Send commands");
        }
    }
    
    // Read from Bluetooth
    if (SerialBT.available()) {
        String msg = "";
        while (SerialBT.available()) {
            char c = SerialBT.read();
            if (c != '\n' && c != '\r') {
                msg += c;
            }
            delay(2);
        }
        
        if (msg.length() > 0) {
            Serial.println("RX: " + msg);
            
            // Handle different command types
            if (msg.startsWith("A")) {
                // Animation command (A0, A1, A2, etc.)
                handleAnimationCommand(msg);
            } else if (msg == "PING") {
                SerialBT.println("PONG");
                display_msg("PING", "PONG", "Test OK");
            } else if (msg == "HELLO") {
                SerialBT.println("Hello from ESP32!");
                display_msg("HELLO", "Response sent");
            } else if (msg == "STATUS") {
                SerialBT.println("ESP32_Eye_Robot:ONLINE");
                display_msg("STATUS", "Online");
            } else {
                // Echo back any other message
                SerialBT.println("ECHO: " + msg);
                display_msg("Received:", msg, "Echo sent");
            }
            
            delay(1000);
        }
    }
    
    // Touch sensor
    if (digitalRead(TOUCH_SENSOR_PIN) == HIGH) {
        Serial.println("Touch detected!");
        if (bt_connected) {
            SerialBT.println("TOUCH_EVENT");
        }
        display_msg("TOUCH!", "Sensor active", "Event sent");
        delay(500);
    }
    
    // Read from Serial (for testing)
    if (Serial.available()) {
        String cmd = Serial.readStringUntil('\n');
        cmd.trim();
        if (cmd.length() > 0 && bt_connected) {
            SerialBT.println(cmd);
            Serial.println("Sent: " + cmd);
        }
    }
    
    delay(10);
}

void handleAnimationCommand(String cmd) {
    Serial.println("Animation command: " + cmd);
    
    // Simple animation responses
    if (cmd == "A0") {
        SerialBT.println("Wake up animation");
        display_msg("A0", "Wake up", "Animation");
    } else if (cmd == "A1") {
        SerialBT.println("Center eyes");
        display_msg("A1", "Center eyes", "Animation");
    } else if (cmd == "A2") {
        SerialBT.println("Move right eye");
        display_msg("A2", "Right eye", "Animation");
    } else if (cmd == "A3") {
        SerialBT.println("Move left eye");
        display_msg("A3", "Left eye", "Animation");
    } else if (cmd == "A4") {
        SerialBT.println("Blink slow");
        display_msg("A4", "Blink slow", "Animation");
    } else if (cmd == "A5") {
        SerialBT.println("Blink fast");
        display_msg("A5", "Blink fast", "Animation");
    } else if (cmd == "A6") {
        SerialBT.println("Happy eyes");
        display_msg("A6", "Happy eyes", "Animation");
    } else if (cmd == "A7") {
        SerialBT.println("Sleep");
        display_msg("A7", "Sleep", "Animation");
    } else if (cmd == "A8") {
        SerialBT.println("Random movement");
        display_msg("A8", "Random", "Movement");
    } else if (cmd == "A9") {
        SerialBT.println("Melt eyes");
        display_msg("A9", "Melt eyes", "Animation");
    } else {
        SerialBT.println("Unknown animation: " + cmd);
        display_msg("Unknown", cmd, "Command");
    }
}
