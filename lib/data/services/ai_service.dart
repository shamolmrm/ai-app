import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/message_model.dart';

// Supports both Anthropic (Claude) and OpenAI. Switch via AppConstants.aiProvider.
class AiService {
  String? _apiKey;
  String? _customModel;
  String? _provider;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(AppConstants.apiKeyKey);
    _customModel = prefs.getString(AppConstants.customModelKey);
    _provider = prefs.getString(AppConstants.aiProviderKey) ?? AppConstants.aiProvider;
  }

  Future<void> saveConfig({
    required String apiKey,
    String? customModel,
    String? provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiKeyKey, apiKey);
    if (customModel != null) {
      await prefs.setString(AppConstants.customModelKey, customModel);
    }
    if (provider != null) {
      await prefs.setString(AppConstants.aiProviderKey, provider);
    }
    _apiKey = apiKey;
    _customModel = customModel;
    _provider = provider ?? _provider;
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  String get activeProvider => _provider ?? AppConstants.aiProvider;

  // Returns a stream of text chunks for real-time display
  Stream<String> streamResponse(List<MessageModel> history, String userMessage) async* {
    await loadConfig();

    if (!isConfigured) {
      throw Exception('API key not configured. Please add your API key in Settings.');
    }

    if (activeProvider == 'anthropic') {
      yield* _streamAnthropic(history, userMessage);
    } else if (activeProvider == 'groq') {
      yield* _streamOpenAICompatible(
        history, userMessage,
        baseUrl: AppConstants.groqBaseUrl,
        defaultModel: AppConstants.groqModel,
        providerName: 'Groq',
      );
    } else {
      yield* _streamOpenAICompatible(
        history, userMessage,
        baseUrl: AppConstants.openaiBaseUrl,
        defaultModel: AppConstants.openaiModel,
        providerName: 'OpenAI',
      );
    }
  }

  // ─── Anthropic (Claude) streaming ─────────────────────────────────────────

  Stream<String> _streamAnthropic(
    List<MessageModel> history,
    String userMessage,
  ) async* {
    final model = _customModel ?? AppConstants.anthropicModel;

    final messages = [
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final request = http.Request(
      'POST',
      Uri.parse('${AppConstants.anthropicBaseUrl}/messages'),
    )
      ..headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': _apiKey!,
        'anthropic-version': '2023-06-01',
      })
      ..body = jsonEncode({
        'model': model,
        'max_tokens': 2048,
        'stream': true,
        'system':
            'You are a helpful, knowledgeable, and friendly AI assistant. '
            'Give clear, accurate, and well-structured responses.',
        'messages': messages,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception(_parseApiError('Anthropic', response.statusCode, body));
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]' || data.isEmpty) continue;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['type'] == 'content_block_delta') {
              final delta = json['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) yield text;
            }
          } catch (_) {
            // Ignore malformed SSE lines
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ─── OpenAI-compatible streaming (OpenAI + Groq) ─────────────────────────

  Stream<String> _streamOpenAICompatible(
    List<MessageModel> history,
    String userMessage, {
    required String baseUrl,
    required String defaultModel,
    required String providerName,
  }) async* {
    final model = _customModel ?? defaultModel;

    final messages = [
      {
        'role': 'system',
        'content':
            'You are a helpful, knowledgeable, and friendly AI assistant. '
            'Give clear, accurate, and well-structured responses.',
      },
      ...history.map((m) => {
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final request = http.Request(
      'POST',
      Uri.parse('$baseUrl/chat/completions'),
    )
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      })
      ..body = jsonEncode({
        'model': model,
        'stream': true,
        'max_tokens': 2048,
        'messages': messages,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception(_parseApiError(providerName, response.statusCode, body));
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]' || data.isEmpty) continue;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            final delta = choices?.first['delta'] as Map<String, dynamic>?;
            final text = delta?['content'] as String?;
            if (text != null && text.isNotEmpty) yield text;
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  String _parseApiError(String provider, int statusCode, String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? json['message'] as String?;
      if (message != null && message.isNotEmpty) {
        if (statusCode == 429) {
          return 'API quota exceeded. Please add billing at '
              '${provider == "OpenAI" ? "platform.openai.com/settings/billing" : "console.anthropic.com"}';
        }
        if (statusCode == 401) return 'Invalid API key. Please check your key in Settings.';
        return message.length > 120 ? '${message.substring(0, 120)}…' : message;
      }
    } catch (_) {}
    return '$provider API error $statusCode. Please check your API key in Settings.';
  }
}
