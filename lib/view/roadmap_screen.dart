// lib/view/roadmap_screen.dart
import 'package:companyenchancer/view/milestone_detailscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/roadmap_controller.dart';
import '../controller/chat_controller.dart';
import '../model/milestone_model.dart';
import '../model/chat_model.dart';
import '../model/app_theme.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roadmapControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildHeader(state),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _MilestoneRow(
                      milestone: state.milestones[i],
                      isLast: i == state.milestones.length - 1,
                      onComplete: () => ref
                          .read(roadmapControllerProvider.notifier)
                          .completeMilestone(state.milestones[i].id),
                    ),
                    childCount: state.milestones.length,
                  ),
                ),
              ),
            ],
          ),
          // Floating chat button
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => _showChatSheet(context),
              backgroundColor: AppTheme.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
              child: const Text('💬', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(RoadmapState state) {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.green,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      '🗺️ Your Growth Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Ahmad's Digital & Export Readiness Path",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.xpProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '⭐ ${state.totalXp} / 1000 XP — Level ${state.level}: ${state.levelLabel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatbotSheet(),
    );
  }
}

// ─── Milestone Row ────────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  final MilestoneModel milestone;
  final bool isLast;
  final VoidCallback onComplete;

  const _MilestoneRow({
    required this.milestone,
    required this.isLast,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _MilestoneNode(status: milestone.status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: milestone.status == MilestoneStatus.done
                        ? AppTheme.green
                        : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MilestoneCard(
                milestone: milestone,
                onComplete: onComplete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Milestone Node ───────────────────────────────────────────────────────────

class _MilestoneNode extends StatefulWidget {
  final MilestoneStatus status;
  const _MilestoneNode({required this.status});

  @override
  State<_MilestoneNode> createState() => _MilestoneNodeState();
}

class _MilestoneNodeState extends State<_MilestoneNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ring = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    if (widget.status == MilestoneStatus.current) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget icon;

    switch (widget.status) {
      case MilestoneStatus.done:
        bg = AppTheme.green;
        icon = const Icon(Icons.check_rounded, color: Colors.white, size: 22);
        break;
      case MilestoneStatus.current:
        bg = AppTheme.blue;
        icon = const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
        );
        break;
      case MilestoneStatus.locked:
        bg = const Color(0xFFD1D5DB);
        icon = const Icon(
          Icons.lock_rounded,
          color: Color(0xFF9CA3AF),
          size: 18,
        );
        break;
    }

    final node = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        boxShadow: widget.status == MilestoneStatus.done
            ? AppTheme.greenGlow(0.35)
            : widget.status == MilestoneStatus.current
            ? AppTheme.blueGlow(0.4)
            : [],
      ),
      child: Center(child: icon),
    );

    if (widget.status != MilestoneStatus.current) return node;

    return AnimatedBuilder(
      animation: _ring,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (1 - _ring.value).clamp(0.0, 1.0),
            child: Container(
              width: 48 + _ring.value * 28,
              height: 48 + _ring.value * 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.blue.withOpacity(0.25 * (1 - _ring.value)),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: node,
    );
  }
}

// ─── Milestone Card ───────────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  final MilestoneModel milestone;
  final VoidCallback onComplete;

  const _MilestoneCard({required this.milestone, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final isCurrent = milestone.status == MilestoneStatus.current;
    final isLocked = milestone.status == MilestoneStatus.locked;

    Color badgeBg;
    Color badgeFg;
    String badgeLabel;
    switch (milestone.status) {
      case MilestoneStatus.done:
        badgeBg = AppTheme.greenPale;
        badgeFg = AppTheme.green;
        badgeLabel = 'COMPLETED';
        break;
      case MilestoneStatus.current:
        badgeBg = AppTheme.bluePale;
        badgeFg = AppTheme.blue;
        badgeLabel = 'IN PROGRESS';
        break;
      case MilestoneStatus.locked:
        badgeBg = const Color(0xFFF3F4F6);
        badgeFg = const Color(0xFF9CA3AF);
        badgeLabel = 'LOCKED';
        break;
    }

    return Opacity(
      opacity: isLocked ? 0.65 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.radiusLg,
          border: isCurrent ? Border.all(color: AppTheme.blue, width: 2) : null,
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${milestone.emoji}  ${milestone.title}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              milestone.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '📅 ${milestone.weekLabel}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '⭐ +${milestone.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                ),
                if (isCurrent) ...[
                  const Spacer(),
                  // In _MilestoneCard — change the Start button:
                ElevatedButton(
                onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => MilestoneDetailScreen(
                          milestone: milestone,
                          onComplete: onComplete,
                        ),
    ),
  ),
  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Start →'),
),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chatbot Bottom Sheet ────────────────────────────────────────────────────

class _ChatbotSheet extends ConsumerStatefulWidget {
  const _ChatbotSheet();

  @override
  ConsumerState<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends ConsumerState<_ChatbotSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    await ref.read(chatControllerProvider.notifier).sendMessage(text);
    _inputCtrl.clear();
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
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
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
                            ...m.sourceDocuments
                                .take(2)
                                .map(
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
            // Input
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
