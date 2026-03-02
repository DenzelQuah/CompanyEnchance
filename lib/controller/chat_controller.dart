import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/chat_model.dart';
import '../model/chat_state.dart';
import '../services/chat_api_service.dart';

class ChatController extends StateNotifier<ChatState> {
  ChatController()
    : _supabase = Supabase.instance.client,
      _chatApi = ChatApiService(),
      super(ChatState.initial()) {
    _bootstrapChat();
  }

  final SupabaseClient _supabase;
  final ChatApiService _chatApi;

  Future<void> _bootstrapChat() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final session = await _supabase
          .from('chat_sessions')
          .select('id')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final sessionId = session?['id'] as String?;
      if (sessionId == null) return;

      final rows = await _supabase
          .from('chat_messages')
          .select('role,content,created_at')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);

      final dbMessages = (rows as List)
          .map(
            (row) => ChatMessage(
              text: row['content'] as String? ?? '',
              isUser: row['role'] == 'user',
            ),
          )
          .where((m) => m.text.trim().isNotEmpty)
          .toList();

      if (dbMessages.isNotEmpty) {
        state = state.copyWith(messages: dbMessages, sessionId: sessionId);
      } else {
        state = state.copyWith(sessionId: sessionId);
      }
    } catch (_) {
      // Keep local chat UI available even if history load fails.
    }
  }

  Future<void> sendMessage(String text) async {
    final input = text.trim();
    if (input.isEmpty || state.isProcessing) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _appendAssistant('Please sign in to use AI roadmap chat.');
      return;
    }

    _appendMessage(ChatMessage(text: input, isUser: true));
    state = state.copyWith(isProcessing: true);

    try {
      final result = await _chatApi.sendMessage(
        userId: userId,
        message: input,
        sessionId: state.sessionId,
      );

      final answer = result.answer.isEmpty
          ? 'No response received from the chat service.'
          : result.answer;

      _appendAssistant(
        answer,
        sourceDocuments: result.sourceDocuments
            .map(
              (doc) => ChatSourceDocument(
                content: (doc['content'] as String? ?? '').trim(),
                metadata: Map<String, dynamic>.from(
                  doc['metadata'] as Map? ?? const {},
                ),
              ),
            )
            .where((doc) => doc.content.isNotEmpty)
            .toList(),
      );
      state = state.copyWith(sessionId: result.sessionId);
    } catch (_) {
      _appendAssistant(
        'Unable to reach the AI backend. Check CHAT_API_URL and backend server status.',
      );
    } finally {
      state = state.copyWith(isProcessing: false);
    }
  }

  void _appendAssistant(
    String text, {
    List<ChatSourceDocument> sourceDocuments = const [],
  }) {
    _appendMessage(
      ChatMessage(text: text, isUser: false, sourceDocuments: sourceDocuments),
    );
  }

  void _appendMessage(ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void clearMessages() {
    state = ChatState.initial().copyWith(sessionId: state.sessionId);
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (_) => ChatController(),
);
