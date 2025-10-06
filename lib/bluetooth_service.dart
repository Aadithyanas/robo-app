import 'dart:async';
import 'dart:io';

// Platform-specific imports
import 'bluetooth_service_mobile.dart' if (dart.library.io) 'bluetooth_service_mobile.dart';
import 'bluetooth_service_desktop.dart' if (dart.library.io) 'bluetooth_service_desktop.dart';

/// Service class for handling Bluetooth communication with ESP32
/// This class manages scanning, connecting, and message exchange
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // Platform-specific implementation
  late final dynamic _platformService;

  // Stream controllers for UI updates
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get messageStream => _messageController.stream;

  // Connection status
  bool get isConnected => _platformService.isConnected;

  /// Initialize the Bluetooth service
  Future<void> initialize() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platform - use mock implementation
        _platformService = DesktopBluetoothService();
        _connectionStatusController.add('Desktop mode: Using mock Bluetooth for testing');
      } else {
        // Mobile platform - use real Bluetooth
        _platformService = MobileBluetoothService();
        _connectionStatusController.add('Mobile mode: Real Bluetooth enabled');
      }
      
      await _platformService.initialize();
    } catch (e) {
      _connectionStatusController.add('Bluetooth initialization failed: $e');
    }
  }

  /// Scan for ESP32 devices
  Future<List<dynamic>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      return await _platformService.scanForDevices(timeout: timeout);
    } catch (e) {
      _connectionStatusController.add('Scan failed: $e');
      return [];
    }
  }

  /// Connect to a specific ESP32 device
  Future<bool> connectToDevice(dynamic device) async {
    try {
      return await _platformService.connectToDevice(device);
    } catch (e) {
      _connectionStatusController.add('Connection failed: $e');
      return false;
    }
  }

  /// Send a message to the ESP32
  Future<bool> sendMessage(String message) async {
    try {
      return await _platformService.sendMessage(message);
    } catch (e) {
      _connectionStatusController.add('Send failed: $e');
      return false;
    }
  }

  /// Read a message from the ESP32
  Future<String?> readMessage() async {
    try {
      return await _platformService.readMessage();
    } catch (e) {
      _connectionStatusController.add('Read failed: $e');
      return null;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      await _platformService.disconnect();
      _connectionStatusController.add('Disconnected from ESP32');
    } catch (e) {
      _connectionStatusController.add('Disconnect failed: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _connectionStatusController.close();
    _messageController.close();
    _platformService.dispose();
  }
}
