// lib/controller/chat_controller.dart
// Manages chatbot message state and AI reply logic.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/chat_model.dart';

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController() : super(ChatMessage.initialMessages);

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    state = [...state, ChatMessage(text: text.trim(), isUser: true)];
    // Simulate async AI reply
    Future.delayed(const Duration(milliseconds: 650), () {
      state = [...state, ChatMessage(text: _generateReply(text), isUser: false)];
    });
  }

  String _generateReply(String input) {
    final q = input.toLowerCase();
    if (q.contains('fb') || q.contains('facebook')) {
      return '📣 3 quick wins for Facebook:\n\n'
          '1. Post at 7–9pm on weekdays — peak Malaysian time\n'
          '2. Use Reels — 3× more organic reach than static posts\n'
          '3. Enable the WhatsApp chat button on your business page\n\n'
          'Want me to build a 2-week content calendar for you?';
    }
    if (q.contains('export') || q.contains('asean')) {
      return '🌍 You\'re 68% export-ready! Your next 3 steps:\n\n'
          '1. Register with MATRADE (free for Malaysian SMEs)\n'
          '2. Get your HS code for customs classification\n'
          '3. Open a multi-currency account (Wise or Maybank)\n\n'
          'Shall I add these to your roadmap?';
    }
    if (q.contains('fund') || q.contains('grant') || q.contains('money')) {
      return '💰 Based on your profile, you qualify for:\n\n'
          '• SME Corp Malaysia — Up to RM 50,000\n'
          '• BPMB Micro Financing — 4.5% p.a.\n'
          '• Cradle Fund CIP300 — For tech-enabled businesses\n\n'
          'Upload your 3-month bank statements this week to unlock all three! 📄';
    }
    if (q.contains('ops') || q.contains('operation')) {
      return '⚙️ Quick operational wins you can do today:\n\n'
          '• Switch to Wave Accounting (free POS + invoicing)\n'
          '• Use Canva for all marketing content — saves ~3h/week\n'
          '• Set up Shopee auto-reply via WhatsApp Business API\n\n'
          'This could free up ~5 hours every week!';
    }
    return '💡 Great question! I\'m cross-referencing your business profile to '
        'generate a personalised recommendation. In the meantime, your '
        'highest-impact action today is completing the financial records '
        'milestone — it unlocks the most opportunities. 🎯';
  }

  void clearMessages() => state = ChatMessage.initialMessages;
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, List<ChatMessage>>(
  (_) => ChatController(),
);
