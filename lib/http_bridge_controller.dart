import 'dart:async';
import 'package:flutter/foundation.dart';
import 'http_bridge_service.dart';
import 'gemini_service.dart';

/// HTTP Bridge Controller that communicates with ESP32 via HTTP bridge
class HttpBridgeController extends ChangeNotifier {
  // Service instances
  final HttpBridgeService _httpBridgeService = HttpBridgeService();
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
  bool get isConnected => _httpBridgeService.isConnected;
  bool get isApiKeySet => _geminiService.isApiKeySet;

  // Stream subscriptions
  StreamSubscription<String>? _connectionStatusSubscription;
  StreamSubscription<String>? _messageSubscription;

  /// Initialize the HTTP bridge controller
  Future<void> initialize() async {
    // Initialize HTTP bridge service
    await _httpBridgeService.initialize();
    
    // Listen to connection status updates
    _connectionStatusSubscription = _httpBridgeService.connectionStatusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    // Listen to incoming messages from ESP32
    _messageSubscription = _httpBridgeService.messageStream.listen((message) {
      _handleIncomingMessage(message);
    });
  }

  /// Set the Gemini API key
  void setApiKey(String key) {
    _apiKey = key;
    _geminiService.setApiKey(key);
    notifyListeners();
  }

  /// Connect to ESP32 via HTTP bridge
  Future<bool> connectToESP32() async {
    try {
      _updateStatus('Connecting to ESP32 via HTTP Bridge...');
      await _httpBridgeService.initialize();
      
      if (_httpBridgeService.isConnected) {
        _updateStatus('Connected to ESP32 via HTTP Bridge');
        return true;
      } else {
        _updateStatus('Failed to connect to ESP32 via HTTP Bridge');
        return false;
      }
    } catch (e) {
      _updateStatus('Connection error: $e');
      return false;
    }
  }

  /// Disconnect from ESP32
  Future<void> disconnect() async {
    try {
      await _httpBridgeService.disconnect();
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
      
      // Send response back to ESP32 via HTTP bridge
      bool sent = await _httpBridgeService.sendTextMessage(response);
      
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

  /// Send animation command to ESP32
  Future<bool> sendAnimationCommand(int animationIndex) async {
    if (!isConnected) {
      _updateStatus('Not connected to ESP32');
      return false;
    }
    
    try {
      bool sent = await _httpBridgeService.sendAnimationCommand(animationIndex);
      if (sent) {
        _updateStatus('Animation command sent: A$animationIndex');
      } else {
        _updateStatus('Failed to send animation command');
      }
      return sent;
    } catch (e) {
      _updateStatus('Animation command error: $e');
      return false;
    }
  }

  /// Send a manual message to ESP32
  Future<bool> sendMessageToESP32(String message) async {
    if (!isConnected) {
      _updateStatus('Not connected to ESP32');
      return false;
    }
    
    try {
      bool sent = await _httpBridgeService.sendTextMessage(message);
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

  /// Update connection status
  void _updateStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
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

  /// Get available animation commands
  List<Map<String, dynamic>> getAnimationCommands() {
    return [
      {'index': 0, 'name': 'Wake up', 'command': 'A0'},
      {'index': 1, 'name': 'Center eyes', 'command': 'A1'},
      {'index': 2, 'name': 'Move right big eye', 'command': 'A2'},
      {'index': 3, 'name': 'Move left big eye', 'command': 'A3'},
      {'index': 4, 'name': 'Blink (slow)', 'command': 'A4'},
      {'index': 5, 'name': 'Blink (fast)', 'command': 'A5'},
      {'index': 6, 'name': 'Happy eyes', 'command': 'A6'},
      {'index': 7, 'name': 'Sleep', 'command': 'A7'},
      {'index': 8, 'name': 'Random saccade', 'command': 'A8'},
      {'index': 9, 'name': 'Melt eyes', 'command': 'A9'},
    ];
  }

  /// Clean up resources
  @override
  void dispose() {
    _connectionStatusSubscription?.cancel();
    _messageSubscription?.cancel();
    _httpBridgeService.dispose();
    super.dispose();
  }
}
