// lib/view/chatbot_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/chat_controller.dart';
import '../model/app_theme.dart';
import '../model/chat_model.dart';

class ChatbotSheet extends ConsumerStatefulWidget {
  /// Optional: If provided, the bot will automatically send this message
  /// when the sheet opens. Used for "SOS" context.
  final String? initialQuery;
  final bool useRag;
  final bool allowUpdates;

  const ChatbotSheet({
    super.key,
    this.initialQuery,
    this.useRag = true,
    this.allowUpdates = true,
  });

  @override
  ConsumerState<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends ConsumerState<ChatbotSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // Auto-send the initial query if it exists (for SOS functionality)
    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    
    // 1. Clear input immediately for better UX
    _inputCtrl.clear();
    
    // 2. Send to controller
    await ref.read(chatControllerProvider.notifier).sendMessage(
      text,
      useRag: widget.useRag,
      allowUpdates: widget.allowUpdates,
    );
    
    // 3. Scroll to bottom after a slight delay to allow UI to render new bubbles
    Future.delayed(const Duration(milliseconds: 700), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final messages = chatState.messages;
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.blue, Color(0xFF7B1FA2)],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Center(
                      child: Text('🤖', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nexus AI Coach',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '● Online',
                        style: TextStyle(
                          color: AppTheme.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl, // Use internal controller for auto-scroll
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  return Align(
                    alignment: m.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: m.isUser ? AppTheme.green : AppTheme.background,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(m.isUser ? 18 : 4),
                          bottomRight: Radius.circular(m.isUser ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.text,
                            style: TextStyle(
                              color: m.isUser
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Source Citations
                          if (!m.isUser && m.sourceDocuments.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Sources',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...m.sourceDocuments.take(2).map(
                                  (doc) => Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.border,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doc.label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.blue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doc.content,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Quick replies
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: QuickReply.defaults.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final qr = QuickReply.defaults[i];
                  return ActionChip(
                    label: Text(
                      qr.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.blue,
                      ),
                    ),
                    backgroundColor: AppTheme.bluePale,
                    side: const BorderSide(color: Color(0xFFBBDEFB)),
                    onPressed: chatState.isProcessing
                        ? null
                        : () => _send(qr.query),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      onSubmitted: chatState.isProcessing
                          ? null
                          : (v) => _send(v),
                      enabled: !chatState.isProcessing,
                      decoration: InputDecoration(
                        hintText: chatState.isProcessing
                            ? 'Processing...'
                            : 'Ask me anything...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: chatState.isProcessing
                        ? null
                        : () => _send(_inputCtrl.text),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppTheme.blue,
                        shape: BoxShape.circle,
                      ),
                      child: chatState.isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
