// lib/model/chat_model.dart
// Chat message model for the AI Chatbot.

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatSourceDocument> sourceDocuments;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.sourceDocuments = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  static List<ChatMessage> get initialMessages => [
    ChatMessage(
      text: '👋 Hi! I\'m your Nexus AI Coach. How can I help you grow today?',
      isUser: false,
    ),
    ChatMessage(
      text:
          'Based on your diagnostic, you\'re 68% export-ready. Want to explore your next steps?',
      isUser: false,
    ),
  ];
}

class ChatSourceDocument {
  final String content;
  final Map<String, dynamic> metadata;

  const ChatSourceDocument({required this.content, this.metadata = const {}});

  String get label {
    final raw = metadata['title']?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Roadmap knowledge source';
  }
}

class QuickReply {
  final String label;
  final String query;

  const QuickReply({required this.label, required this.query});

  static const List<QuickReply> defaults = [
    QuickReply(label: '📣 Attract customers on FB', query: 'facebook'),
    QuickReply(label: '🌍 Start exporting', query: 'export'),
    QuickReply(label: '💰 Get funding', query: 'funding'),
    QuickReply(label: '📊 Improve operations', query: 'operations'),
  ];
}
