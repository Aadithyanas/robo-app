import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service class for communicating with Google's Gemini API
/// Handles API calls and response parsing for ESP32 requests
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Gemini API configuration
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';
  String? _apiKey;

  /// Set the API key for Gemini
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Check if API key is set
  bool get isApiKeySet => _apiKey != null && _apiKey!.isNotEmpty;

  /// Generate content using Gemini API
  /// Takes a prompt and returns a simplified response suitable for OLED display
  Future<String> generateContent(String prompt) async {
    if (!isApiKeySet) {
      throw Exception('Gemini API key not set');
    }

    try {
      // Prepare the request URL
      final String url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
      
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 100, // Limit response length for OLED
        }
      };

      // Make the API call
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Extract the generated text
        String generatedText = _extractGeneratedText(responseData);
        
        // Simplify the response for OLED display
        return _simplifyForOLED(generatedText);
      } else {
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gemini API call failed: $e');
    }
  }

  /// Extract generated text from Gemini API response
  String _extractGeneratedText(Map<String, dynamic> responseData) {
    try {
      // Navigate through the response structure
      final List<dynamic> candidates = responseData['candidates'] ?? [];
      if (candidates.isEmpty) {
        return 'No response generated';
      }

      final Map<String, dynamic> firstCandidate = candidates[0];
      final Map<String, dynamic> content = firstCandidate['content'] ?? {};
      final List<dynamic> parts = content['parts'] ?? [];
      
      if (parts.isEmpty) {
        return 'No content in response';
      }

      final Map<String, dynamic> firstPart = parts[0];
      return firstPart['text'] ?? 'No text in response';
    } catch (e) {
      return 'Error parsing response: $e';
    }
  }

  /// Simplify text for OLED display (max ~20 characters)
  String _simplifyForOLED(String text) {
    // Remove extra whitespace and newlines
    String simplified = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // Remove common words that take up space
    simplified = simplified
        .replaceAll(RegExp(r'\b(the|and|or|but|in|on|at|to|for|of|with|by)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Truncate to fit OLED (approximately 20 characters)
    if (simplified.length > 20) {
      simplified = '${simplified.substring(0, 17)}...';
    }
    
    // Convert to uppercase for better OLED readability
    return simplified.toUpperCase();
  }

  /// Process ESP32 requests and return appropriate responses
  Future<String> processESP32Request(String request) async {
    // Clean the request
    String cleanRequest = request.trim().toUpperCase();
    
    // Map common ESP32 requests to proper prompts
    String prompt = _mapRequestToPrompt(cleanRequest);
    
    // Get response from Gemini
    String response = await generateContent(prompt);
    
    return response;
  }

  /// Map ESP32 requests to appropriate Gemini prompts
  String _mapRequestToPrompt(String request) {
    // Handle common ESP32 request patterns
    if (request.contains('WEATHER') || request.contains('WEATHER?')) {
      return 'What is the current weather? Give a brief summary.';
    } else if (request.contains('TIME') || request.contains('TIME?')) {
      return 'What time is it now? Give just the time.';
    } else if (request.contains('DATE') || request.contains('DATE?')) {
      return 'What is today\'s date? Give just the date.';
    } else if (request.contains('HELLO') || request.contains('HELLO?')) {
      return 'Say hello in a friendly way.';
    } else if (request.contains('JOKE') || request.contains('JOKE?')) {
      return 'Tell me a short joke.';
    } else if (request.contains('QUOTE') || request.contains('QUOTE?')) {
      return 'Give me an inspirational quote.';
    } else if (request.contains('HELP') || request.contains('HELP?')) {
      return 'List some commands I can ask for: weather, time, date, hello, joke, quote.';
    } else {
      // For unknown requests, use the original request as prompt
      return request.replaceAll('?', '');
    }
  }

  /// Test the API connection
  Future<bool> testConnection() async {
    try {
      String response = await generateContent('Say hello');
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
