// lib/view/roadmap_screen.dart
import 'package:companyenchancer/controller/survey_controller.dart';
import 'package:companyenchancer/view/chatbot_sheet.dart';
import 'package:companyenchancer/view/milestone_detailscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';
import '../controller/roadmap_controller.dart';
import '../model/milestone_model.dart';
import '../model/app_theme.dart';


class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.userEmail != next.userEmail ||
          previous?.status != next.status) {
        ref.read(surveyControllerProvider.notifier).ensureLoadedForCurrentUser();
        ref.read(roadmapControllerProvider.notifier).ensureLoadedForCurrentUser();
      }
    });

    ref.read(surveyControllerProvider.notifier).ensureLoadedForCurrentUser();
    ref.read(roadmapControllerProvider.notifier).ensureLoadedForCurrentUser();

    final state = ref.watch(roadmapControllerProvider);
    final survey = ref.watch(surveyControllerProvider);
    final businessName = survey.businessName.trim().isEmpty
        ? 'Your Business'
        : survey.businessName.trim();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          if (state.isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.blue),
                  SizedBox(height: 16),
                  Text(
                    'Generating your personalized roadmap...',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (state.milestones.isEmpty)
            const Center(
              child: Text(
                'No roadmap available. Please complete your profile.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
          CustomScrollView(
            slivers: [
              _buildHeader(state, businessName),
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

  SliverAppBar _buildHeader(RoadmapState state, String businessName) {
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
                    Text(
                      'Roadmap for $businessName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
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
      builder: (_) => const ChatbotSheet(),
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
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Text(
                        '📅 ${milestone.weekLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '⭐ +${milestone.xpReward} XP',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Consumer(
                          builder: (context, ref, _) {
                            final survey =
                                ref.watch(surveyControllerProvider);
                            return MilestoneDetailScreen(
                              milestone: milestone,
                              onComplete: onComplete,
                              survey: survey,
                            );
                          },
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


