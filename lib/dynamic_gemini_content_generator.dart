import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart' as genUI;
import 'package:genui_gemini/api.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DynamicGeminiContentGenerator implements genUI.ContentGenerator {
  final String apiKey;
  final genUI.Catalog catalog;
  late final GenerativeModel _model;

  final _a2uiMessageController = StreamController<genUI.A2uiMessage>.broadcast();
  final _textResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<genUI.ContentGeneratorError>.broadcast();
  final ValueNotifier<bool> _isProcessingNotifier = ValueNotifier<bool>(false);

  DynamicGeminiContentGenerator({
    required this.apiKey,
    required this.catalog,
  }) {
    _model = GenerativeModel(
      model: GeminiApi.model,
      apiKey: apiKey,
      systemInstruction: Content.system(_buildSystemPrompt()),
    );
  }

  String _buildSystemPrompt() {
    return '''
You are a helpful AI assistant that can display information using UI components.

IMPORTANT: You must respond with a valid JSON object. No other text allowed.

Available UI components in catalog "${catalog.catalogId}":

1. WeatherCard - For current weather information
   Properties: city (required), temp (required), condition, humidity
   Use when: User asks about current weather in a city

2. ForecastCard - For weather forecasts
   Properties: city (required), date (required), condition (required), highTemp, lowTemp, rainChance
   Use when: User asks about future weather, rain predictions, forecasts

3. InfoCard - For general information, explanations, answers
   Properties: title (required), content (required), icon (info/warning/success/error/question)
   Use when: User asks general questions, needs explanations, factual information

4. ListCard - For listing items
   Properties: title (required), items (required, comma-separated string)
   Use when: User asks for lists, multiple items, options

5. TextCard - For simple text responses
   Properties: text (required)
   Use when: Simple conversational responses, greetings

RESPONSE FORMAT (strict JSON only):
{
  "ui": {
    "component": "ComponentName",
    "props": {
      "propName": "value"
    }
  },
  "text": "Optional explanation text"
}

EXAMPLES:

User: "What's the weather in Tokyo?"
Response:
{
  "ui": {
    "component": "WeatherCard",
    "props": {
      "city": "Tokyo",
      "temp": "22°C",
      "condition": "Partly Cloudy",
      "humidity": "65%"
    }
  },
  "text": "Here's the current weather in Tokyo."
}

User: "When will it rain in Paris?"
Response:
{
  "ui": {
    "component": "ForecastCard",
    "props": {
      "city": "Paris",
      "date": "December 28, 2025",
      "condition": "Rainy",
      "highTemp": "12°C",
      "lowTemp": "6°C",
      "rainChance": "85%"
    }
  },
  "text": "Rain is expected in Paris on December 28th."
}

User: "Who invented the telephone?"
Response:
{
  "ui": {
    "component": "InfoCard",
    "props": {
      "title": "Invention of the Telephone",
      "content": "Alexander Graham Bell is credited with inventing the first practical telephone in 1876. He was a Scottish-born scientist and engineer who conducted extensive research on hearing and speech.",
      "icon": "info"
    }
  }
}

User: "List 5 programming languages"
Response:
{
  "ui": {
    "component": "ListCard",
    "props": {
      "title": "Popular Programming Languages",
      "items": "Python, JavaScript, Java, C++, Dart"
    }
  }
}

User: "Hello"
Response:
{
  "ui": {
    "component": "TextCard",
    "props": {
      "text": "Hello! I'm your AI assistant. I can help you with weather information, answer questions, provide explanations, and more. What would you like to know?"
    }
  }
}

RULES:
1. ALWAYS respond with valid JSON only - no markdown, no extra text
2. Choose the most appropriate component for the user's question
3. Provide realistic, helpful data in the props
4. For weather data, use realistic temperatures and conditions
5. If unsure which component to use, prefer InfoCard for explanations or TextCard for simple responses
''';
  }

  @override
  Stream<genUI.A2uiMessage> get a2uiMessageStream => _a2uiMessageController.stream;

  @override
  Stream<String> get textResponseStream => _textResponseController.stream;

  @override
  Stream<genUI.ContentGeneratorError> get errorStream => _errorController.stream;

  @override
  ValueListenable<bool> get isProcessing => _isProcessingNotifier;

  @override
  Future<void> sendRequest(
      genUI.ChatMessage message, {
        genUI.A2UiClientCapabilities? clientCapabilities,
        Iterable<genUI.ChatMessage>? history,
      }) async {
    _isProcessingNotifier.value = true;

    try {
      final userText = message is genUI.UserMessage ? message.text : message.toString();
      debugPrint('📝 User: $userText');

      final response = await _model.generateContent([Content.text(userText)]);
      final responseText = response.text ?? '';
      debugPrint('🤖 Raw response: $responseText');

      Map<String, dynamic>? jsonResponse;
      try {
        String cleanedResponse = responseText.trim();
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        }
        if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        }
        cleanedResponse = cleanedResponse.trim();

        jsonResponse = json.decode(cleanedResponse) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('⚠️ Failed to parse JSON: $e');
        jsonResponse = {
          'ui': {
            'component': 'TextCard',
            'props': {'text': responseText}
          }
        };
      }

      final ui = jsonResponse['ui'] as Map<String, dynamic>?;
      if (ui != null) {
        final componentName = ui['component'] as String? ?? 'TextCard';
        final props = ui['props'] as Map<String, dynamic>? ?? {};

        final surfaceId = 'surface-${DateTime.now().millisecondsSinceEpoch}';
        final componentId = 'component-${DateTime.now().millisecondsSinceEpoch}';

        debugPrint('🎨 Creating $componentName with props: $props');

        final Map<String, Object?> componentProperties = {
          componentName: {
            for (final entry in props.entries)
              entry.key: {'literalString': entry.value.toString()}
          }
        };

        _a2uiMessageController.add(genUI.BeginRendering(
          surfaceId: surfaceId,
          root: componentId,
          catalogId: catalog.catalogId,
        ));

        await Future.delayed(const Duration(milliseconds: 30));

        _a2uiMessageController.add(genUI.SurfaceUpdate(
          surfaceId: surfaceId,
          components: [
            genUI.Component(
              id: componentId,
              componentProperties: componentProperties,
            ),
          ],
        ));

        debugPrint('✅ Surface created: $surfaceId');
      }

      final textResponse = jsonResponse['text'] as String?;
      if (textResponse != null && textResponse.isNotEmpty) {
        _textResponseController.add(textResponse);
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Error: $e');
      _errorController.add(genUI.ContentGeneratorError(e, stackTrace));
    } finally {
      _isProcessingNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _a2uiMessageController.close();
    _textResponseController.close();
    _errorController.close();
    _isProcessingNotifier.dispose();
  }
}