import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Mobile implementation of Bluetooth service for Android/iOS with Classic Bluetooth
class MobileBluetoothService {
  // Stream controllers for UI updates
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Method channel for native Bluetooth communication
  static const MethodChannel _channel = MethodChannel('bluetooth_serial');

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Getters for streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get messageStream => _messageController.stream;

  /// Initialize the Bluetooth service
  Future<void> initialize() async {
    try {
      // Check if we're on a supported platform
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        _connectionStatusController.add('Real Bluetooth not available on desktop. Use Android for ESP32 connection.');
        return;
      }

      // Set up method call handler
      _channel.setMethodCallHandler(_handleMethodCall);

      _connectionStatusController.add('Bluetooth initialized - Ready to scan for ESP32');
    } catch (e) {
      _connectionStatusController.add('Bluetooth initialization failed: $e');
    }
  }

  /// Handle method calls from native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDataReceived':
        String data = call.arguments.toString();
        _messageController.add(data);
        _connectionStatusController.add('Received: $data');
        break;
      case 'onConnectionStateChanged':
        bool connected = call.arguments as bool;
        _isConnected = connected;
        if (connected) {
          _connectionStatusController.add('Connected to ESP32');
        } else {
          _connectionStatusController.add('Disconnected from ESP32');
        }
        break;
    }
  }

  /// Scan for ESP32 devices
  Future<List<dynamic>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _connectionStatusController.add('Real Bluetooth scanning not available on desktop');
      return [];
    }

    try {
      _connectionStatusController.add('Scanning for ESP32 devices...');
      
      // Call native method to scan for devices
      final List<dynamic> devices = await _channel.invokeMethod('scanForDevices', {
        'timeout': timeout.inSeconds,
      });
      
      // Filter for ESP32 devices
      List<dynamic> esp32Devices = devices.where((device) {
        String name = device['name'] ?? '';
        return name.contains('ESP32') || name.contains('Eye_Robot');
      }).toList();
      
      if (esp32Devices.isEmpty) {
        _connectionStatusController.add('No ESP32 devices found. Make sure your ESP32 is powered on and Bluetooth is enabled.');
      } else {
        _connectionStatusController.add('Found ${esp32Devices.length} ESP32 device(s)');
        for (var device in esp32Devices) {
          _connectionStatusController.add('Found ESP32: ${device['name']}');
        }
      }
      
      return esp32Devices;
    } catch (e) {
      _connectionStatusController.add('Scan failed: $e');
      return [];
    }
  }

  /// Connect to a specific ESP32 device
  Future<bool> connectToDevice(dynamic device) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _connectionStatusController.add('Real Bluetooth connection not available on desktop');
      return false;
    }

    try {
      _connectionStatusController.add('Connecting to ${device['name']}...');
      
      // Call native method to connect
      bool success = await _channel.invokeMethod('connectToDevice', {
        'address': device['address'],
        'name': device['name'],
      });
      
      if (success) {
        _isConnected = true;
        _connectionStatusController.add('Connected to ${device['name']} - Ready for communication');
      } else {
        _connectionStatusController.add('Connection failed');
      }
      
      return success;
    } catch (e) {
      _connectionStatusController.add('Connection failed: $e');
      return false;
    }
  }

  /// Send a message to the ESP32
  Future<bool> sendMessage(String message) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _connectionStatusController.add('Real Bluetooth messaging not available on desktop');
      return false;
    }

    if (!isConnected) {
      _connectionStatusController.add('Not connected to ESP32');
      return false;
    }

    try {
      // Call native method to send message
      bool success = await _channel.invokeMethod('sendMessage', {
        'message': message,
      });
      
      if (success) {
        _connectionStatusController.add('Sent to ESP32: $message');
      } else {
        _connectionStatusController.add('Send failed');
      }
      
      return success;
    } catch (e) {
      _connectionStatusController.add('Send failed: $e');
      return false;
    }
  }

  /// Read a message from the ESP32
  Future<String?> readMessage() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return null;
    }

    if (!isConnected) {
      return null;
    }

    try {
      // Call native method to read message
      String? message = await _channel.invokeMethod('readMessage');
      if (message != null && message.isNotEmpty) {
        _messageController.add(message);
        return message;
      }
    } catch (e) {
      _connectionStatusController.add('Read failed: $e');
    }
    
    return null;
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _connectionStatusController.add('Real Bluetooth disconnect not available on desktop');
      return;
    }

    try {
      // Call native method to disconnect
      await _channel.invokeMethod('disconnect');
      _isConnected = false;
      _connectionStatusController.add('Disconnected from ESP32');
    } catch (e) {
      _connectionStatusController.add('Disconnect failed: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _connectionStatusController.close();
    _messageController.close();
  }
}