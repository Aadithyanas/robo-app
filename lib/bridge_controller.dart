import 'dart:async';
import 'package:flutter/foundation.dart';
import 'bluetooth_service.dart';
import 'gemini_service.dart';

/// Controller class that bridges ESP32 and Gemini API
/// Manages the flow of messages between Bluetooth and AI service
class BridgeController extends ChangeNotifier {
  // Service instances
  final BluetoothService _bluetoothService = BluetoothService();
  final GeminiService _geminiService = GeminiService();

  // State variables
  String _connectionStatus = 'Not connected';
  String _lastESP32Request = '';
  String _lastGeminiResponse = '';
  String _apiKey = '';
  bool _isProcessing = false;

  // Getters
  String get connectionStatus => _connectionStatus;
  String get lastESP32Request => _lastESP32Request;
  String get lastGeminiResponse => _lastGeminiResponse;
  String get apiKey => _apiKey;
  bool get isProcessing => _isProcessing;
  bool get isConnected => _bluetoothService.isConnected;
  bool get isApiKeySet => _geminiService.isApiKeySet;

  // Stream subscriptions
  StreamSubscription<String>? _connectionStatusSubscription;
  StreamSubscription<String>? _messageSubscription;

  /// Initialize the bridge controller
  Future<void> initialize() async {
    // Initialize Bluetooth service
    await _bluetoothService.initialize();
    
    // Listen to connection status updates
    _connectionStatusSubscription = _bluetoothService.connectionStatusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    // Listen to incoming messages from ESP32
    _messageSubscription = _bluetoothService.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });
  }

  /// Set the Gemini API key
  void setApiKey(String key) {
    _apiKey = key;
    _geminiService.setApiKey(key);
    notifyListeners();
  }

  /// Scan for ESP32 devices
  Future<List<dynamic>> scanForDevices() async {
    try {
      _updateStatus('Scanning for ESP32 devices...');
      List<dynamic> devices = await _bluetoothService.scanForDevices();
      _updateStatus('Found ${devices.length} ESP32 device(s)');
      return devices;
    } catch (e) {
      _updateStatus('Scan failed: $e');
      return [];
    }
  }

  /// Connect to a specific ESP32 device
  Future<bool> connectToDevice(dynamic device) async {
    try {
      _updateStatus('Connecting to ESP32...');
      bool success = await _bluetoothService.connectToDevice(device);
      
      if (success) {
        _updateStatus('Connected to ESP32');
        _startMessageListening();
      } else {
        _updateStatus('Failed to connect to ESP32');
      }
      
      return success;
    } catch (e) {
      _updateStatus('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from ESP32
  Future<void> disconnect() async {
    try {
      await _bluetoothService.disconnect();
      _updateStatus('Disconnected from ESP32');
    } catch (e) {
      _updateStatus('Disconnect error: $e');
    }
  }

  /// Handle incoming messages from ESP32
  void _handleIncomingMessage(String message) {
    if (message.trim().isEmpty) return;
    
    _lastESP32Request = message.trim();
    _updateStatus('Received from ESP32: $message');
    
    // Process the message if API key is set
    if (isApiKeySet) {
      _processESP32Request(message);
    } else {
      _updateStatus('API key not set - cannot process request');
    }
  }

  /// Process ESP32 request through Gemini API
  Future<void> _processESP32Request(String request) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      _updateStatus('Processing request with Gemini...');
      
      // Get response from Gemini
      String response = await _geminiService.processESP32Request(request);
      _lastGeminiResponse = response;
      
      // Send response back to ESP32
      bool sent = await _bluetoothService.sendMessage(response);
      
      if (sent) {
        _updateStatus('Response sent to ESP32: $response');
      } else {
        _updateStatus('Failed to send response to ESP32');
      }
      
    } catch (e) {
      _lastGeminiResponse = 'Error: $e';
      _updateStatus('Processing failed: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Send a test message to Gemini (for debugging)
  Future<void> testGemini(String testPrompt) async {
    if (!isApiKeySet) {
      _updateStatus('API key not set');
      return;
    }
    
    _isProcessing = true;
    notifyListeners();
    
    try {
      _updateStatus('Testing Gemini API...');
      String response = await _geminiService.generateContent(testPrompt);
      _lastGeminiResponse = response;
      _updateStatus('Gemini test successful');
    } catch (e) {
      _lastGeminiResponse = 'Test failed: $e';
      _updateStatus('Gemini test failed: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Start listening for messages from ESP32
  void _startMessageListening() {
    // The message listening is already set up in initialize()
    // This method can be used for additional setup if needed
    _updateStatus('Listening for ESP32 messages...');
  }

  /// Update connection status
  void _updateStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
  }

  /// Send a manual message to ESP32
  Future<bool> sendMessageToESP32(String message) async {
    if (!isConnected) {
      _updateStatus('Not connected to ESP32');
      return false;
    }
    
    try {
      bool sent = await _bluetoothService.sendMessage(message);
      if (sent) {
        _updateStatus('Message sent to ESP32: $message');
      } else {
        _updateStatus('Failed to send message to ESP32');
      }
      return sent;
    } catch (e) {
      _updateStatus('Send error: $e');
      return false;
    }
  }

  /// Get available ESP32 commands
  List<String> getAvailableCommands() {
    return [
      'WEATHER?',
      'TIME?',
      'DATE?',
      'HELLO?',
      'JOKE?',
      'QUOTE?',
      'HELP?'
    ];
  }

  /// Clean up resources
  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _messageSubscription?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }
}
