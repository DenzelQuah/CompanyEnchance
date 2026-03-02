import 'chat_model.dart';

class PendingRoadmapAction {
  final String actionType;
  final String implementationPlan;
  final String? conflictMessage;
  final Map<String, dynamic> payload;

  const PendingRoadmapAction({
    required this.actionType,
    required this.implementationPlan,
    this.conflictMessage,
    required this.payload,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final String? sessionId;
  final PendingRoadmapAction? pendingAction;

  const ChatState({
    required this.messages,
    this.isProcessing = false,
    this.sessionId,
    this.pendingAction,
  });

  factory ChatState.initial() =>
      ChatState(messages: ChatMessage.initialMessages);

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isProcessing,
    String? sessionId,
    PendingRoadmapAction? pendingAction,
    bool clearPendingAction = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isProcessing: isProcessing ?? this.isProcessing,
      sessionId: sessionId ?? this.sessionId,
      pendingAction: clearPendingAction
          ? null
          : (pendingAction ?? this.pendingAction),
    );
  }
}
