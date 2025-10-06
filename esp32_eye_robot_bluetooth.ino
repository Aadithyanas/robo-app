#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "BluetoothSerial.h"

#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels

// Declaration for an SSD1306 display connected to I2C (SDA, SCL pins)
// The pins for I2C are defined by the Wire-library.
// On an arduino UNO: A4(SDA), A5(SCL)
// On an arduino MEGA 2560: 20(SDA), 21(SCL)
// On an arduino LEONARDO: 2(SDA), 3(SCL), ...
#define OLED_RESET -1 // Reset pin # (or -1 if sharing Arduino reset pin)
#define SCREEN_ADDRESS 0x3C ///< See datasheet for Address; 0x3D for 128x64, 0x3C for 128x32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Define the TTP223 touch sensor pin
#define TOUCH_SENSOR_PIN 2 // Connect TTP223 sensor to ESP32 D2 (GPIO2)

// Bluetooth Serial object
BluetoothSerial SerialBT;

// states for demo
int demo_mode = 1;
static const int max_animation_index = 8;
int current_animation_index = 0;

//reference state
int ref_eye_height = 40;
int ref_eye_width = 40;
int ref_space_between_eye = 10;
int ref_corner_radius = 10;
//current state of the eyes
int left_eye_height = ref_eye_height;
int left_eye_width = ref_eye_width;
int left_eye_x = 32;
int left_eye_y = 32;
int right_eye_x = 32 + ref_eye_width + ref_space_between_eye;
int right_eye_y = 32;
int right_eye_height = ref_eye_height;
int right_eye_width = ref_eye_width;

// Bluetooth connection status
bool bluetooth_connected = false;
unsigned long last_bluetooth_check = 0;
const unsigned long BLUETOOTH_CHECK_INTERVAL = 1000; // Check every second

void draw_eyes(bool update = true) {
    display.clearDisplay();
    //draw from center
    int x = int(left_eye_x - left_eye_width / 2);
    int y = int(left_eye_y - left_eye_height / 2);
    display.fillRoundRect(x, y, left_eye_width, left_eye_height, ref_corner_radius, SSD1306_WHITE);
    x = int(right_eye_x - right_eye_width / 2);
    y = int(right_eye_y - right_eye_height / 2);
    display.fillRoundRect(x, y, right_eye_width, right_eye_height, ref_corner_radius, SSD1306_WHITE);
    if (update) {
        display.display();
    }
}

void center_eyes(bool update = true) {
    //move eyes to the center of the display, defined by SCREEN_WIDTH, SCREEN_HEIGHT
    left_eye_height = ref_eye_height;
    left_eye_width = ref_eye_width;
    right_eye_height = ref_eye_height;
    right_eye_width = ref_eye_width;

    left_eye_x = SCREEN_WIDTH / 2 - ref_eye_width / 2 - ref_space_between_eye / 2;
    left_eye_y = SCREEN_HEIGHT / 2;
    right_eye_x = SCREEN_WIDTH / 2 + ref_eye_width / 2 + ref_space_between_eye / 2;
    right_eye_y = SCREEN_HEIGHT / 2;

    draw_eyes(update);
}

void blink(int speed = 12) {
    draw_eyes();

    for (int i = 0; i < 3; i++) {
        left_eye_height = left_eye_height - speed;
        right_eye_height = right_eye_height - speed;
        draw_eyes();
        delay(1);
    }
    for (int i = 0; i < 3; i++) {
        left_eye_height = left_eye_height + speed;
        right_eye_height = right_eye_height + speed;

        draw_eyes();
        delay(1);
    }
}

void sleep() {
    left_eye_height = 2;
    right_eye_height = 2;
    draw_eyes(true);
}

void wakeup() {
    sleep();

    for (int h = 0; h <= ref_eye_height; h += 2) {
        left_eye_height = h;
        right_eye_height = h;
        draw_eyes(true);
    }
}

void happy_eye() {
    center_eyes(false);
    //draw inverted triangle over eye lower part
    int offset = ref_eye_height / 2;
    for (int i = 0; i < 10; i++) {
        display.fillTriangle(left_eye_x - left_eye_width / 2 - 1, left_eye_y + offset, left_eye_x + left_eye_width / 2 + 1, left_eye_y + 5 + offset, left_eye_x - left_eye_width / 2 - 1, left_eye_y + left_eye_height + offset, SSD1306_BLACK);
        //display.fillRect(left_eye_x-left_eye_width/2-1, left_eye_y+5, left_eye_width+1, 20,SSD1306_BLACK);

        display.fillTriangle(right_eye_x + right_eye_width / 2 + 1, right_eye_y + offset, right_eye_x - left_eye_width / 2 - 1, right_eye_y + 5 + offset, right_eye_x + right_eye_width / 2 + 1, right_eye_y + right_eye_height + offset, SSD1306_BLACK);
        //display.fillRect(right_eye_x-right_eye_width/2-1, right_eye_y+5, right_eye_width+1, 20,SSD1306_BLACK);
        offset -= 2;
        display.display();
        delay(1);
    }

    display.display();
    delay(1000);
}

void saccade(int direction_x, int direction_y) {
    //quick movement of the eye, no size change. stay at position after movement, will not move back, call again with opposite direction
    //direction == -1 : move left
    //direction == 1 : move right

    int direction_x_movement_amplitude = 8;
    int direction_y_movement_amplitude = 6;
    int blink_amplitude = 8;

    for (int i = 0; i < 1; i++) {
        left_eye_x += direction_x_movement_amplitude * direction_x;
        right_eye_x += direction_x_movement_amplitude * direction_x;
        left_eye_y += direction_y_movement_amplitude * direction_y;
        right_eye_y += direction_y_movement_amplitude * direction_y;

        right_eye_height -= blink_amplitude;
        left_eye_height -= blink_amplitude;
        draw_eyes();
        delay(1);
    }

    for (int i = 0; i < 1; i++) {
        left_eye_x += direction_x_movement_amplitude * direction_x;
        right_eye_x += direction_x_movement_amplitude * direction_x;
        left_eye_y += direction_y_movement_amplitude * direction_y;
        right_eye_y += direction_y_movement_amplitude * direction_y;

        right_eye_height += blink_amplitude;
        left_eye_height += blink_amplitude;

        draw_eyes();
        delay(1);
    }
}

void move_right_big_eye() {
    move_big_eye(1);
}

void move_left_big_eye() {
    move_big_eye(-1);
}

void move_big_eye(int direction) {
    //direction == -1 : move left
    //direction == 1 : move right

    int direction_oversize = 1;
    int direction_movement_amplitude = 2;
    int blink_amplitude = 5;

    for (int i = 0; i < 3; i++) {
        left_eye_x += direction_movement_amplitude * direction;
        right_eye_x += direction_movement_amplitude * direction;
        right_eye_height -= blink_amplitude;
        left_eye_height -= blink_amplitude;
        if (direction > 0) {
            right_eye_height += direction_oversize;
            right_eye_width += direction_oversize;
        } else {
            left_eye_height += direction_oversize;
            left_eye_width += direction_oversize;
        }

        draw_eyes();
        delay(1);
    }
    for (int i = 0; i < 3; i++) {
        left_eye_x += direction_movement_amplitude * direction;
        right_eye_x += direction_movement_amplitude * direction;
        right_eye_height += blink_amplitude;
        left_eye_height += blink_amplitude;
        if (direction > 0) {
            right_eye_height += direction_oversize;
            right_eye_width += direction_oversize;
        } else {
            left_eye_height += direction_oversize;
            left_eye_width += direction_oversize;
        }
        draw_eyes();
        delay(1);
    }

    delay(1000);

    for (int i = 0; i < 3; i++) {
        left_eye_x -= direction_movement_amplitude * direction;
        right_eye_x -= direction_movement_amplitude * direction;
        right_eye_height -= blink_amplitude;
        left_eye_height -= blink_amplitude;
        if (direction > 0) {
            right_eye_height -= direction_oversize;
            right_eye_width -= direction_oversize;
        } else {
            left_eye_height -= direction_oversize;
            left_eye_width -= direction_oversize;
        }
        draw_eyes();
        delay(1);
    }
    for (int i = 0; i < 3; i++) {
        left_eye_x -= direction_movement_amplitude * direction;
        right_eye_x -= direction_movement_amplitude * direction;
        right_eye_height += blink_amplitude;
        left_eye_height += blink_amplitude;
        if (direction > 0) {
            right_eye_height -= direction_oversize;
            right_eye_width -= direction_oversize;
        } else {
            left_eye_height -= direction_oversize;
            left_eye_width -= direction_oversize;
        }
        draw_eyes();
        delay(1);
    }

    center_eyes();
}

void melt_eyes() {
    // This function makes the eyes "melt" downwards
    int melt_speed = 5; // How fast the eyes move down
    int current_left_y = left_eye_y;
    int current_right_y = right_eye_y;

    // Gradually move the eyes downwards and shrink them
    for (int i = 0; i < 30; i++) {
        current_left_y += melt_speed;
        current_right_y += melt_speed;

        left_eye_y = current_left_y;
        right_eye_y = current_right_y;

        // Optional: Add a slight wobble effect
        left_eye_x += random(-1, 2);
        right_eye_x += random(-1, 2);

        // Also make the eyes slightly narrower as they "melt"
        left_eye_width -= 1;
        right_eye_width -= 1;

        // Make sure the width doesn't go below zero
        if (left_eye_width < 0) left_eye_width = 0;
        if (right_eye_width < 0) right_eye_width = 0;

        draw_eyes();
        delay(50);
    }
}

// Function to draw a single heart at a specific position and size
void draw_heart(int x, int y, int w, int h) {
    display.fillTriangle(x, y + h / 2,
                         x - w / 2, y - h / 2,
                         x + w / 2, y - h / 2, SSD1306_WHITE);
    display.fillCircle(x - w / 4, y - h / 2, w / 4, SSD1306_WHITE);
    display.fillCircle(x + w / 4, y - h / 2, w / 4, SSD1306_WHITE);
}

// New function to handle the heart-pumping animation
void animate_pumping_hearts() {
    int max_heart_width = 30;
    int max_heart_height = 25;
    int blush_radius = 3;
    int blush_offset_x = 15;
    int blush_offset_y = 10;
    int pump_amplitude = 5; // How much the heart size changes

    for (int i = 0; i < 3; i++) { // Repeat the animation a few times
        // Expand the hearts (pump in)
        for (int j = 0; j < pump_amplitude; j++) {
            display.clearDisplay();
            draw_heart(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 2, max_heart_width + j, max_heart_height + j);
            draw_heart(SCREEN_WIDTH * 3 / 4, SCREEN_HEIGHT / 2, max_heart_width + j, max_heart_height + j);
            
            // Draw blush
            display.fillCircle(SCREEN_WIDTH / 4 - blush_offset_x, SCREEN_HEIGHT / 2 + blush_offset_y, blush_radius, SSD1306_WHITE);
            display.fillCircle(SCREEN_WIDTH * 3 / 4 + blush_offset_x, SCREEN_HEIGHT / 2 + blush_offset_y, blush_radius, SSD1306_WHITE);
            
            display.display();
            delay(10);
        }

        // Shrink the hearts (pump out)
        for (int j = pump_amplitude; j > 0; j--) {
            display.clearDisplay();
            draw_heart(SCREEN_WIDTH / 4, SCREEN_HEIGHT / 2, max_heart_width + j, max_heart_height + j);
            draw_heart(SCREEN_WIDTH * 3 / 4, SCREEN_HEIGHT / 2, max_heart_width + j, max_heart_height + j);
            
            // Draw blush
            display.fillCircle(SCREEN_WIDTH / 4 - blush_offset_x, SCREEN_HEIGHT / 2 + blush_offset_y, blush_radius, SSD1306_WHITE);
            display.fillCircle(SCREEN_WIDTH * 3 / 4 + blush_offset_x, SCREEN_HEIGHT / 2 + blush_offset_y, blush_radius, SSD1306_WHITE);
            
            display.display();
            delay(10);
        }
    }
}

// Function to display connection status on OLED
void display_connection_status() {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    
    // Display title
    display.setCursor(0, 0);
    display.println("Eye Robot BT");
    
    // Display connection status
    display.setCursor(0, 16);
    if (bluetooth_connected) {
        display.println("BT: Connected");
        display.setCursor(0, 32);
        display.println("Ready for commands");
    } else {
        display.println("BT: Disconnected");
        display.setCursor(0, 32);
        display.println("Waiting...");
    }
    
    // Display current animation
    display.setCursor(0, 48);
    display.print("Anim: ");
    display.println(current_animation_index);
    
    display.display();
}

// Function to handle Bluetooth commands
void handle_bluetooth_command(String command) {
    command.trim();
    Serial.println("Received BT command: " + command);
    
    // Show received command on display
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("BT Command:");
    display.setCursor(0, 16);
    if (command.length() > 20) {
        display.println(command.substring(0, 17) + "...");
    } else {
        display.println(command);
    }
    display.display();
    delay(1000);
    
    // Process command
    if (command.startsWith("A")) {
        // Animation command: A0, A1, A2, etc.
        String animStr = command.substring(1);
        int animIndex = animStr.toInt();
        if (animIndex >= 0 && animIndex <= max_animation_index) {
            launch_animation_with_index(animIndex);
        }
    } else if (command == "CONNECT") {
        // Connection acknowledgment
        SerialBT.println("CONNECTED");
        display_connection_status();
    } else if (command == "PING") {
        // Ping response
        SerialBT.println("PONG");
    } else {
        // Unknown command
        SerialBT.println("UNKNOWN");
    }
}

void launch_animation_with_index(int animation_index) {
    if (animation_index > max_animation_index) {
        animation_index = 8;
    }

    switch (animation_index) {
        case 0:
            wakeup();
            break;
        case 1:
            center_eyes(true);
            break;
        case 2:
            move_right_big_eye();
            break;
        case 3:
            move_left_big_eye();
            break;
        case 4:
            blink(10);
            break;
        case 5:
            blink(20);
            break;
        case 6:
            happy_eye();
            break;
        case 7:
            sleep();
            break;
        case 8:
            center_eyes(true);
            for (int i = 0; i < 20; i++) {
                int dir_x = random(-1, 2);
                int dir_y = random(-1, 2);
                saccade(dir_x, dir_y);
                delay(1);
                saccade(-dir_x, -dir_y);
                delay(1);
            }
            break;
        case 9:
            melt_eyes();
            center_eyes(); // Return to normal state after melting
            break;
    }
    
    // Show connection status after animation
    display_connection_status();
}

void setup() {
    // put your setup code here, to run once:

    // SSD1306_SWITCHCAPVCC = generate display voltage from 3.3V internally
    display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS);

    //for usb communication
    Serial.begin(115200);

    // Configure the touch sensor pin
    pinMode(TOUCH_SENSOR_PIN, INPUT);

    // Initialize Bluetooth
    SerialBT.begin("ESP32_Eye_Robot"); // Bluetooth device name
    Serial.println("Bluetooth device is now discoverable as 'ESP32_Eye_Robot'");

    // Show initial display buffer contents on the screen --
    // the library initializes this with an Adafruit splash screen.

    // Clear the buffer
    display.clearDisplay();

    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println(F("Eye Robot BT"));
    display.setCursor(0, 16);
    display.println(F("Initializing..."));
    display.display();
    delay(2000);
    
    // Show initial status
    display_connection_status();
    sleep();
    delay(2000);
}

void loop() {
    // Check Bluetooth connection status
    if (millis() - last_bluetooth_check >= BLUETOOTH_CHECK_INTERVAL) {
        bool was_connected = bluetooth_connected;
        bluetooth_connected = SerialBT.hasClient();
        
        // If connection status changed, update display
        if (was_connected != bluetooth_connected) {
            if (bluetooth_connected) {
                Serial.println("Bluetooth client connected!");
                SerialBT.println("CONNECTED");
                // Show connection animation
                center_eyes();
                blink(15);
                blink(15);
            } else {
                Serial.println("Bluetooth client disconnected!");
                // Show disconnection animation
                melt_eyes();
                center_eyes();
            }
            display_connection_status();
        }
        
        last_bluetooth_check = millis();
    }

    // Check for incoming Bluetooth messages
    if (SerialBT.available()) {
        String receivedMessage = SerialBT.readString();
        receivedMessage.trim();
        handle_bluetooth_command(receivedMessage);
    }

    // Check for touch sensor trigger
    if (digitalRead(TOUCH_SENSOR_PIN) == HIGH) {
        Serial.println("Touch detected! Heart eyes with blush!");
        demo_mode = 0; // Disable demo mode
        animate_pumping_hearts(); // Launch the new heart eyes animation
        center_eyes(); // Return to normal state
        display_connection_status();
        delay(500); // Debounce delay
        demo_mode = 1; // Re-enable demo mode after the animation
    } else {
        // Demo mode and serial commands
        if (demo_mode == 1 && !bluetooth_connected) {
            // cycle animations only when not connected to Bluetooth
            launch_animation_with_index(current_animation_index++);
            if (current_animation_index > max_animation_index) {
                current_animation_index = 0;
            }
        }
    }

    //send A0 - A5 for animation 0 to 5
    if (Serial.available()) {
        String data = Serial.readString();
        data.trim();
        char cmd = data[0];

        if (cmd == 'A') {
            demo_mode = 0;

            String arg = data.substring(1, data.length());
            int anim = arg.toInt();
            launch_animation_with_index(anim);
            Serial.print(cmd);
            Serial.print(arg);
        }
    }
}

