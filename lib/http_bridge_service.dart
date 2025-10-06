import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// HTTP Bridge Service for communicating with ESP32 via Serial Terminal bridge
class HttpBridgeService {
  // Stream controllers for UI updates
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Bridge server configuration
  static const String _bridgeUrl = 'http://localhost:8080';
  
  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Getters for streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get messageStream => _messageController.stream;

  /// Initialize the HTTP bridge service
  Future<void> initialize() async {
    try {
      _connectionStatusController.add('HTTP Bridge initialized - Ready to connect to ESP32');
      
      // Test connection to bridge server
      await _testBridgeConnection();
    } catch (e) {
      _connectionStatusController.add('HTTP Bridge initialization failed: $e');
    }
  }

  /// Test connection to bridge server
  Future<void> _testBridgeConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_bridgeUrl/get_status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isConnected = true;
        _connectionStatusController.add('Connected to ESP32 via HTTP Bridge');
      } else {
        _isConnected = false;
        _connectionStatusController.add('Bridge server not responding');
      }
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add('Cannot connect to bridge server: $e');
    }
  }

  /// Send a command to ESP32 via bridge
  Future<bool> sendCommand(String command) async {
    if (!_isConnected) {
      _connectionStatusController.add('Not connected to bridge server');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_bridgeUrl/send_command'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'command': command}),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _connectionStatusController.add('Command sent: $command');
        _messageController.add('ESP32 Response: ${data['message']}');
        return true;
      } else {
        _connectionStatusController.add('Failed to send command: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _connectionStatusController.add('Send command failed: $e');
      return false;
    }
  }

  /// Send animation command to ESP32
  Future<bool> sendAnimationCommand(int animationIndex) async {
    return await sendCommand('A$animationIndex');
  }

  /// Send text message to ESP32 (for Gemini responses)
  Future<bool> sendTextMessage(String message) async {
    return await sendCommand(message);
  }

  /// Disconnect from bridge
  Future<void> disconnect() async {
    _isConnected = false;
    _connectionStatusController.add('Disconnected from HTTP Bridge');
  }

  /// Clean up resources
  void dispose() {
    _connectionStatusController.close();
    _messageController.close();
  }
}
