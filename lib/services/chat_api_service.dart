import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatApiResult {
  final String answer;
  final String sessionId;
  final List<Map<String, dynamic>> sourceDocuments;

  const ChatApiResult({
    required this.answer,
    required this.sessionId,
    required this.sourceDocuments,
  });
}

class ChatApiService {
  String get _endpoint {
    final configured = dotenv.env['CHAT_API_URL'];
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    // Android emulator default for local backend.
    return 'http://10.0.2.2:8000/chat';
  }

  Future<ChatApiResult> sendMessage({
    required String userId,
    required String message,
    String? sessionId,
    bool useRag = true,
    bool allowUpdates = true,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse(_endpoint);
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(
        utf8.encode(
          jsonEncode({
            'user_id': userId,
            'message': message,
            'session_id': sessionId,
            'use_rag': useRag,
            'allow_updates': allowUpdates,
          }),
        ),
      );

      final response = await request.close().timeout(const Duration(seconds: 30));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Chat API failed (${response.statusCode}): $body');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawSessionId = (data['session_id'] as String? ?? sessionId ?? '').trim();
      if (rawSessionId.isEmpty) {
        throw Exception('Chat API returned an empty session_id.');
      }
      final docs = (data['source_documents'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      return ChatApiResult(
        answer: (data['answer'] as String? ?? '').trim(),
        sessionId: rawSessionId,
        sourceDocuments: docs,
      );
    } finally {
      client.close(force: true);
    }
  }
}
