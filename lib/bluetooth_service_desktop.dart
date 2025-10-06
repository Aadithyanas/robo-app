import 'dart:async';
import 'dart:math';

/// Desktop implementation of Bluetooth service (mock for Windows/Linux/macOS)
/// This provides a simulated Bluetooth experience for testing UI and API functionality
class DesktopBluetoothService {
  // Mock state
  bool _isConnected = false;
  String _connectedDeviceName = '';
  Timer? _mockMessageTimer;
  final Random _random = Random();

  // Stream controllers for UI updates
  final StreamController<String> _connectionStatusController = StreamController<String>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  Stream<String> get messageStream => _messageController.stream;

  // Connection status
  bool get isConnected => _isConnected;

  /// Initialize the Bluetooth service
  Future<void> initialize() async {
    _connectionStatusController.add('Desktop Bluetooth Mock initialized');
    _connectionStatusController.add('Note: Real Bluetooth not available on desktop');
  }

  /// Scan for ESP32 devices (mock)
  Future<List<dynamic>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async {
    _connectionStatusController.add('Scanning for ESP32 devices... (Mock)');
    
    // Simulate scanning delay
    await Future.delayed(Duration(seconds: 2));
    
    // Return mock devices
    List<MockBluetoothDevice> mockDevices = [
      MockBluetoothDevice('ESP32_Device_1', 'Mock ESP32 Device 1'),
      MockBluetoothDevice('ESP32_Device_2', 'Mock ESP32 Device 2'),
      MockBluetoothDevice('ESP32_Test', 'Mock ESP32 Test Device'),
    ];
    
    _connectionStatusController.add('Found ${mockDevices.length} mock ESP32 device(s)');
    return mockDevices;
  }

  /// Connect to a specific ESP32 device (mock)
  Future<bool> connectToDevice(dynamic device) async {
    try {
      _connectionStatusController.add('Connecting to ${device.name}... (Mock)');
      
      // Simulate connection delay
      await Future.delayed(Duration(seconds: 1));
      
      _isConnected = true;
      _connectedDeviceName = device.name;
      _connectionStatusController.add('Connected to ${device.name} (Mock)');
      
      // Start sending mock messages
      _startMockMessageTimer();
      
      return true;
    } catch (e) {
      _connectionStatusController.add('Connection failed: $e');
      return false;
    }
  }

  /// Send a message to the ESP32 (mock)
  Future<bool> sendMessage(String message) async {
    if (!_isConnected) {
      _connectionStatusController.add('Not connected to ESP32');
      return false;
    }

    try {
      _connectionStatusController.add('Sent: $message (Mock)');
      return true;
    } catch (e) {
      _connectionStatusController.add('Send failed: $e');
      return false;
    }
  }

  /// Read a message from the ESP32 (mock)
  Future<String?> readMessage() async {
    if (!_isConnected) {
      return null;
    }

    // Return a mock message
    List<String> mockMessages = [
      'WEATHER?',
      'TIME?',
      'DATE?',
      'HELLO?',
      'JOKE?',
      'QUOTE?',
      'HELP?'
    ];
    
    String mockMessage = mockMessages[_random.nextInt(mockMessages.length)];
    _messageController.add(mockMessage);
    return mockMessage;
  }

  /// Disconnect from the current device (mock)
  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _connectedDeviceName = '';
      _mockMessageTimer?.cancel();
      _connectionStatusController.add('Disconnected from ESP32 (Mock)');
    } catch (e) {
      _connectionStatusController.add('Disconnect failed: $e');
    }
  }

  /// Start mock message timer to simulate ESP32 sending messages
  void _startMockMessageTimer() {
    _mockMessageTimer?.cancel();
    _mockMessageTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_isConnected) {
        readMessage(); // This will trigger a mock message
      } else {
        timer.cancel();
      }
    });
  }

  /// Clean up resources
  void dispose() {
    _mockMessageTimer?.cancel();
    _connectionStatusController.close();
    _messageController.close();
  }
}

/// Mock Bluetooth device class for desktop testing
class MockBluetoothDevice {
  final String id;
  final String name;
  final String platformName;

  MockBluetoothDevice(this.id, this.name) : platformName = name;
  
  String get remoteId => id;
}
