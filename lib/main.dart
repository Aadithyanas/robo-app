import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'http_bridge_controller.dart';
import 'http_bridge_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HttpBridgeController()..initialize(),
      child: MaterialApp(
        title: 'ESP32 ↔ Gemini Bridge',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BridgeHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class BridgeHomePage extends StatefulWidget {
  @override
  _BridgeHomePageState createState() => _BridgeHomePageState();
}

class _BridgeHomePageState extends State<BridgeHomePage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _testPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _testPromptController.text = 'What is the weather today?';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _testPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32 ↔ Gemini Bridge'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Consumer<HttpBridgeController>(
        builder: (context, bridge, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // API Key Section
                _buildApiKeySection(bridge),
                
                SizedBox(height: 20),
                
                // Connection Status
                _buildConnectionStatus(bridge),
                
                SizedBox(height: 20),
                
                // Bluetooth Controls
                _buildBluetoothControls(bridge),
                
                SizedBox(height: 20),
                
                // Message Display
                _buildMessageDisplay(bridge),
                
                SizedBox(height: 20),
                
                // Test Controls
                _buildTestControls(bridge),
                
                SizedBox(height: 20),
                
                // Available Commands
                _buildAvailableCommands(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApiKeySection(HttpBridgeController bridge) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemini API Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Gemini API key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_apiKeyController.text.isNotEmpty) {
                  bridge.setApiKey(_apiKeyController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API Key set successfully')),
                  );
                }
              },
              child: Text('Set API Key'),
            ),
            if (bridge.isApiKeySet)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '✓ API Key configured',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(HttpBridgeController bridge) {
    Color statusColor = Colors.red;
    if (bridge.connectionStatus.contains('Connected')) {
      statusColor = Colors.green;
    } else if (bridge.connectionStatus.contains('Scanning') || bridge.connectionStatus.contains('Connecting')) {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.bluetooth, color: statusColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bridge.connectionStatus,
                    style: TextStyle(
                      fontSize: 16,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (bridge.isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Processing...', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothControls(HttpBridgeController bridge) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bluetooth Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: bridge.isConnected ? null : () => _connectToESP32(bridge),
                    icon: bridge.isConnected 
                        ? Icon(Icons.check)
                        : Icon(Icons.bluetooth),
                    label: Text(bridge.isConnected ? 'Connected' : 'Connect to ESP32'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bridge.isConnected ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: bridge.isConnected ? () => bridge.disconnect() : null,
                    icon: Icon(Icons.bluetooth_disabled),
                    label: Text('Disconnect'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'HTTP Bridge Mode: Connect to ESP32 via Serial Terminal',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageDisplay(HttpBridgeController bridge) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Exchange',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (bridge.lastESP32Request.isNotEmpty) ...[
              Text(
                'ESP32 says:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bridge.lastESP32Request,
                  style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (bridge.lastGeminiResponse.isNotEmpty) ...[
              Text(
                'Gemini replies:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bridge.lastGeminiResponse,
                  style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (bridge.lastESP32Request.isEmpty && bridge.lastGeminiResponse.isEmpty)
              Text(
                'No messages yet. Connect to ESP32 and send a request.',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControls(HttpBridgeController bridge) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _testPromptController,
                    decoration: InputDecoration(
                      labelText: 'Test Prompt',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: bridge.isApiKeySet && !bridge.isProcessing
                      ? () => bridge.testGemini(_testPromptController.text)
                      : null,
                  child: Text('Test Gemini'),
                ),
              ],
            ),
            SizedBox(height: 10),
            if (bridge.isConnected)
              ElevatedButton.icon(
                onPressed: () => _sendTestMessage(bridge),
                icon: Icon(Icons.send),
                label: Text('Send Test Message to ESP32'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCommands() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available ESP32 Commands',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'WEATHER?',
                'TIME?',
                'DATE?',
                'HELLO?',
                'JOKE?',
                'QUOTE?',
                'HELP?',
              ].map((command) => Chip(
                label: Text(command),
                backgroundColor: Colors.blue[100],
              )).toList(),
            ),
            SizedBox(height: 10),
            Text(
              'Send any of these commands from your ESP32 to get AI responses!',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToESP32(HttpBridgeController bridge) async {
    bool success = await bridge.connectToESP32();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ESP32 via HTTP Bridge')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ESP32 via HTTP Bridge')),
      );
    }
  }

  Future<void> _sendTestMessage(HttpBridgeController bridge) async {
    bool sent = await bridge.sendMessageToESP32('HELLO?');
    if (sent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test message sent to ESP32')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send test message')),
      );
    }
  }
}
