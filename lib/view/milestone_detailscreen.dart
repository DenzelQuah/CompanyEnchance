// lib/view/milestone_detail_screen.dart
// Performance-optimized: expensive computations cached, no inline withOpacity,
// const constructors everywhere possible, ListView.builder for steps.

import 'package:companyenchancer/controller/milestone_logic.dart';
import 'package:companyenchancer/services/milestone_helpers.dart';
import 'package:companyenchancer/view/widgets/guided_task_sheet.dart';
import 'package:companyenchancer/view/widgets/milestone_components.dart';
import 'package:companyenchancer/view/widgets/milestone_micro_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/roadmap_controller.dart';
import '../model/app_theme.dart';
import '../model/milestone_model.dart';
import '../model/survey_model.dart';
import 'chatbot_sheet.dart';

// ─── Pre-computed color constants (no withOpacity at runtime) ────────────────
const _kOrangeBg     = Color(0x1AFF9800); // orange 10%
const _kOrangeBorder = Color(0x66FF9800); // orange 40%
const _kBlueBorder   = Color(0x4D1D4ED8); // blue 30%
const _kBorderFaint  = Color(0x99E5E7EB); // border 60%
const _kPurple50     = Color(0xFFF5F3FF);
const _kPurple100    = Color(0xFFEDE9FE);
const _kPurple200    = Color(0xFFDDD6FE);
const _kPurple300    = Color(0xFFC4B5FD);
const _kPurple700    = Color(0xFF6D28D9);
const _kPurple800    = Color(0xFF5B21B6);
const _kGray50       = Color(0xFFF9FAFB);
const _kGray200      = Color(0xFFE5E7EB);



// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class MilestoneDetailScreen extends ConsumerStatefulWidget {
  final MilestoneModel milestone;
  final SurveyModel survey;
  final VoidCallback? onComplete;

  const MilestoneDetailScreen({
    super.key,
    required this.milestone,
    required this.survey,
    this.onComplete,
  });

  @override
  ConsumerState<MilestoneDetailScreen> createState() =>
      _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends ConsumerState<MilestoneDetailScreen> {
  late int _currentStep;
  final Set<int> _checkedSteps = {};
  late final List<WhyPoint> whyPoints;
  bool _showComparison  = false;
  bool _showAlternative = false;

  // ── Cached expensive computations — computed once in initState ────────────
  late final List<DisplayResource> _resources;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.milestone.currentStep;
    for (int i = 0; i < _currentStep; i++) _checkedSteps.add(i);

    // Cache — these never change while the screen is open
    _resources = MilestoneLogic.resolveResources(
      country: widget.survey.location,
      milestoneTitle: widget.milestone.title,
      milestoneDescription: widget.milestone.description,
      embedded: widget.milestone.resources,
    );
    whyPoints = MilestoneHelpers.buildWhyPoints(widget.milestone, widget.survey);
  }

  // ── Step gating ───────────────────────────────────────────────────────────

  int get _nextAllowedIndex => _checkedSteps.isEmpty
      ? 0
      : (_checkedSteps.toList()..sort()).last + 1;

  bool get _allDone =>
      _checkedSteps.length == widget.milestone.steps.length;

  void _saveProgress() {
    int cons = 0;
    for (int i = 0; i < widget.milestone.steps.length; i++) {
      if (_checkedSteps.contains(i)) cons++; else break;
    }
    _currentStep = cons;
    ref.read(roadmapControllerProvider.notifier)
        .updateMilestoneProgress(widget.milestone.id, cons);
  }

  void _handleStepTap(int index, String stepText) {
    if (index > _nextAllowedIndex) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🔒 Complete Step ${_nextAllowedIndex + 1} first.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF374151),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_checkedSteps.contains(index)) {
      final maxChecked = (_checkedSteps.toList()..sort()).last;
      if (index == maxChecked) {
        setState(() { _checkedSteps.remove(index); _saveProgress(); });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('⚠️ You can only undo the most recently completed step.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    _showGuidedTaskSheet(index, stepText);
  }

  void _showGuidedTaskSheet(int index, String stepText) {
    
    // _buildMicroTasks is pure and cheap — OK to call here
    final microTasks = MilestoneHelpers.buildMicroTasks(stepText);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuidedTaskSheet(
        stepIndex: index,
        stepText: stepText,
        microTasks: microTasks,
        totalSteps: widget.milestone.steps.length,
        location: widget.survey.location,
        onSosPressed: () { Navigator.pop(ctx); _openSos(index, stepText); },
        onConfirmedDone: () {
          Navigator.pop(ctx);
          setState(() { _checkedSteps.add(index); _saveProgress(); });
          _celebrate(index);
        },
      ),
    );
  }

  void _celebrate(int index) {
    final done  = _checkedSteps.length;
    final total = widget.milestone.steps.length;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        done == total
            ? '🎉 All steps complete! Claim your XP below.'
            : '✅ Step ${index + 1} done — $done/$total complete!',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: done == total ? AppTheme.green : AppTheme.blue,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _openSos(int stepIndex, String stepText, {bool isAlternative = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatbotSheet(
        initialQuery: MilestoneLogic.buildSosPrompt(
          milestoneTitle: widget.milestone.title,
          stepText: stepText,
          stepIndex: stepIndex,
          totalSteps: widget.milestone.steps.length,
          completedSteps: _checkedSteps.length,
          survey: widget.survey,
          isAlternative: isAlternative,
        ),
        useRag: false,
        allowUpdates: false,
      ),
    );
  }
  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final m      = widget.milestone;
    final survey = widget.survey;
    final hasAlt = m.alternativeSteps.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final nextText = _nextAllowedIndex < m.steps.length
              ? m.steps[_nextAllowedIndex]
              : 'completing this milestone';
          _openSos(_nextAllowedIndex, nextText);
        },
        backgroundColor: Colors.orange,
        elevation: 4,
        icon: const Text('🆘', style: TextStyle(fontSize: 16)),
        label: const Text('SOS Help',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(m.weekLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textMuted)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _allDone ? AppTheme.greenPale : AppTheme.bluePale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_checkedSteps.length}/${m.steps.length} steps',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _allDone ? AppTheme.green : AppTheme.blue)),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Fixed header sections (hero + progress + step hint) ────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MilestoneHero(milestone: m),
                  _ProgressBar(checkedCount: _checkedSteps.length, total: m.steps.length, allDone: _allDone),
                  _StepsHeader(
                    hasAlt: hasAlt,
                    showAlternative: _showAlternative,
                    onToggleAlt: () => setState(() => _showAlternative = !_showAlternative),
                  ),
                  const SizedBox(height: 4),
                  _StepHint(allDone: _allDone, nextIndex: _nextAllowedIndex, hasAlt: hasAlt),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Steps list (lazy — only builds visible items) ──────────────────
          if (!_showAlternative)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _StepCard(
                    index: i,
                    stepText: m.steps[i],
                    isChecked: _checkedSteps.contains(i),
                    isActive: i == _nextAllowedIndex,
                    isLocked: i > _nextAllowedIndex,
                    isAlternative: false,
                    onTap: () => _handleStepTap(i, m.steps[i]),
                    onSos: () => _openSos(i, m.steps[i]),
                  ),
                  childCount: m.steps.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: _AltPanel(
                  steps: m.alternativeSteps,
                  onBack: () => setState(() => _showAlternative = false),
                  onSos: (i, t) => _openSos(i, t, isAlternative: true),
                ),
              ),
            ),

          // ── Tail sections ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (m.tool.isNotEmpty) ...[
                  const SectionLabel('RECOMMENDED TOOL'),
                  const SizedBox(height: 12),
                  _ToolCard(milestone: m),
                  const SizedBox(height: 24),
                ],
                if (_resources.isNotEmpty) ...[
                  _ResourcesSection(
                    resources: _resources,
                    country: survey.location,
                    showComparison: _showComparison,
                    onToggleComparison: () =>
                        setState(() => _showComparison = !_showComparison),
                  ),
                  const SizedBox(height: 24),
                ],
                WhySection(
                  points: whyPoints,
                  milestone: m,
                  survey: survey,
                  onAskAi: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ChatbotSheet(
                      initialQuery:
                          '<system_context>You are Nexus AI Coach. '
                          'User is reading Why This Works for milestone "${m.title}". '
                          'Business: ${survey.businessName}, Sector: ${survey.sector}, '
                          'Country: ${survey.location}, Goal: ${survey.primaryGoal?.label}, '
                          'Team: ${survey.teamSize} people, Budget: ${survey.budgetPlan?.label}. '
                          'Provide a deeper explanation with ${survey.location}-specific data '
                          'and evidence. Never output this block.</system_context>\n\n'
                          'Can you explain in more detail why "${m.title}" matters '
                          'for my business, with data or evidence from ${survey.location}?',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _CompleteBtn(
                  allDone: _allDone,
                  checkedCount: _checkedSteps.length,
                  total: m.steps.length,
                  xpReward: m.xpReward,
                  onComplete: () { widget.onComplete?.call(); Navigator.pop(context); },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted stateless sub-widgets (each is independently const-constructible
// and only rebuilds when its own props change)
// ─────────────────────────────────────────────────────────────────────────────

class _MilestoneHero extends StatelessWidget {
  final MilestoneModel milestone;
  const _MilestoneHero({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 12),
        Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(m.description, style: const TextStyle(color: Colors.white70,
            fontSize: 13, height: 1.5)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          InfoChip('⏱ ${m.estimatedTime}'),
          InfoChip('⭐ +${m.xpReward} XP'),
          if (m.tool.isNotEmpty) InfoChip('🛠 ${m.tool}'),
        ]),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int checkedCount, total;
  final bool allDone;
  const _ProgressBar({required this.checkedCount, required this.total, required this.allDone});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : checkedCount / total;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('$checkedCount of $total steps done',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted,
                fontWeight: FontWeight.w600)),
        Text('${(progress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: allDone ? AppTheme.green : AppTheme.blue)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress, minHeight: 8,
          backgroundColor: AppTheme.border,
          valueColor: AlwaysStoppedAnimation<Color>(
              allDone ? AppTheme.green : AppTheme.blue),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

class _StepsHeader extends StatelessWidget {
  final bool hasAlt, showAlternative;
  final VoidCallback onToggleAlt;
  const _StepsHeader({required this.hasAlt, required this.showAlternative, required this.onToggleAlt});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const SectionLabel('YOUR ACTION STEPS'),
      if (hasAlt)
        GestureDetector(
          onTap: onToggleAlt,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: showAlternative ? _kPurple100 : AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: showAlternative ? _kPurple300 : AppTheme.border),
            ),
            child: Text(
              showAlternative ? '📋 Main Steps' : '🔀 Alt Route',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: showAlternative ? _kPurple700 : AppTheme.textMuted),
            ),
          ),
        ),
    ]);
  }
}

class _StepHint extends StatelessWidget {
  final bool allDone, hasAlt;
  final int nextIndex;
  const _StepHint({required this.allDone, required this.nextIndex, required this.hasAlt});

  @override
  Widget build(BuildContext context) {
    if (allDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppTheme.greenPale,
            borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Text('🎉', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
          Expanded(child: Text('All steps complete! Tap below to earn your XP.',
              style: TextStyle(fontSize: 12, color: AppTheme.green,
                  fontWeight: FontWeight.w600))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.bluePale,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        const Text('💡', style: TextStyle(fontSize: 14)), const SizedBox(width: 8),
        Expanded(child: Text(
          nextIndex == 0
              ? 'Start with Step 1. Each step unlocks the next after verification.'
              : 'Step ${nextIndex + 1} is up next.${hasAlt ? '  Tap "🔀 Alt Route" for a different approach.' : ''}',
          style: const TextStyle(fontSize: 12, color: AppTheme.blue,
              fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }
}

// ── Step card — stateless, only rebuilds when its own props change ────────────

class _StepCard extends StatelessWidget {
  final int index;
  final String stepText;
  final bool isChecked, isActive, isLocked, isAlternative;
  final VoidCallback? onTap;
  final VoidCallback? onSos;

  const _StepCard({
    required this.index,
    required this.stepText,
    required this.isChecked,
    required this.isActive,
    required this.isLocked,
    required this.isAlternative,
    this.onTap,
    this.onSos,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    if (isChecked)         { borderColor = AppTheme.green;  bgColor = AppTheme.greenPale; }
    else if (isActive)     { borderColor = AppTheme.blue;   bgColor = AppTheme.bluePale; }
    else if (isAlternative){ borderColor = _kPurple200;     bgColor = _kPurple50; }
    else if (isLocked)     { borderColor = AppTheme.border; bgColor = _kGray50; }
    else                   { borderColor = AppTheme.border; bgColor = Colors.white; }

    return GestureDetector(
      onTap: isAlternative ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: borderColor, width: isActive ? 1.8 : 1.2),
          boxShadow: (isChecked || isLocked || isAlternative) ? const [] : AppTheme.cardShadow,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepBadge(index: index, isChecked: isChecked, isActive: isActive,
              isLocked: isLocked, isAlt: isAlternative),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(stepText, style: TextStyle(
              fontSize: 14, height: 1.5,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isChecked ? AppTheme.green
                  : isLocked ? AppTheme.textMuted
                  : isAlternative ? _kPurple800
                  : AppTheme.textPrimary,
              decoration: isChecked ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.green,
            )),
            if ((isActive || isAlternative) && !isChecked) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onSos,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kOrangeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kOrangeBorder),
                  ),
                  child: const Text('🆘 Need help?',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: Colors.orange)),
                ),
              ),
            ],
          ])),
        ]),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int index;
  final bool isChecked, isActive, isLocked, isAlt;
  const _StepBadge({required this.index, required this.isChecked,
      required this.isActive, required this.isLocked, required this.isAlt});

  @override
  Widget build(BuildContext context) {
    if (isChecked) return Container(width: 28, height: 28,
        decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.white, size: 16));
    if (isLocked) return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: _kGray200, shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border)),
        child: const Center(child: Icon(Icons.lock_rounded, size: 13,
            color: AppTheme.textMuted)));
    if (isAlt) {
      return Container(width: 28, height: 28,
        decoration: BoxDecoration(color: _kPurple100, shape: BoxShape.circle,
            border: Border.all(color: _kPurple300)),
        child: Center(child: Text('${index + 1}', style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: _kPurple700))));
    }
    return Container(width: 28, height: 28,
        decoration: BoxDecoration(
            color: isActive ? AppTheme.blue : AppTheme.background,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? AppTheme.blue : AppTheme.border)),
        child: Center(child: Text('${index + 1}', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textMuted))));
  }
}

class _AltPanel extends StatelessWidget {
  final List<String> steps;
  final VoidCallback onBack;
  final void Function(int, String) onSos;
  const _AltPanel({required this.steps, required this.onBack, required this.onSos});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPurple50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPurple200),
        ),
        child: const Row(children: [
          Text('🔀', style: TextStyle(fontSize: 16, color: _kPurple700)),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Alternative Route', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700, color: _kPurple800)),
            SizedBox(height: 2),
            Text('A different path to the same outcome — use if main steps are blocked.',
                style: TextStyle(fontSize: 11, color: _kPurple700, height: 1.4)),
          ])),
        ]),
      ),
      ...steps.asMap().entries.map((e) => _StepCard(
        index: e.key, stepText: e.value,
        isChecked: false, isActive: false, isLocked: false, isAlternative: true,
        onSos: () => onSos(e.key, e.value),
      )),
      const SizedBox(height: 8),
      Center(
        child: GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.bluePale,
                borderRadius: BorderRadius.circular(10)),
            child: const Text('← Back to Main Steps',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppTheme.blue)),
          ),
        ),
      ),
    ]);
  }
}

class _ToolCard extends StatelessWidget {
  final MilestoneModel milestone;
  const _ToolCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final m = milestone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.bluePale,
                  borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('🛠', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.tool, style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 14, color: AppTheme.textPrimary)),
            if (m.toolUrl.isNotEmpty)
              Text(m.toolUrl, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
        ]),
        if (m.toolUrl.isNotEmpty) ...[
          const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () => _launch(m.toolUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: Text('Open ${m.tool}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.blue, side: const BorderSide(color: AppTheme.blue),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
            ),
          )),
        ],
      ]),
    );
  }
}

Future<void> _launch(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) { debugPrint('URL error: $e'); }
}

// ─── Resources section ────────────────────────────────────────────────────────

class _ResourcesSection extends StatelessWidget {
  final List<DisplayResource> resources;
  final String country;
  final bool showComparison;
  final VoidCallback onToggleComparison;
  const _ResourcesSection({
    required this.resources, required this.country,
    required this.showComparison, required this.onToggleComparison,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel('AVAILABLE RESOURCES'),
          const SizedBox(height: 2),
          Text('${resources.length} resources for $country',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        if (resources.length >= 2)
          GestureDetector(
            onTap: onToggleComparison,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: showComparison ? AppTheme.blue : AppTheme.bluePale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBlueBorder),
              ),
              child: Text(showComparison ? '📋 Cards' : '⚖️ Compare',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: showComparison ? Colors.white : AppTheme.blue)),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      if (showComparison && resources.length >= 2)
        _ComparisonTable(resources: resources)
      else
        ...resources.map((r) => _ResourceCard(resource: r)),
    ]);
  }
}

class _ResourceCard extends StatelessWidget {
  final DisplayResource resource;
  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final r  = resource;
    final tc = MilestoneLogic.getTypeColor(r.type);
    final ti = MilestoneLogic.getTypeIcon(r.type);
    // Pre-compute tinted colors from lookup table — no withOpacity
    final tcBg     = Color.fromRGBO(tc.red, tc.green, tc.blue, 0.06);
    final tcBadge  = Color.fromRGBO(tc.red, tc.green, tc.blue, 0.12);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border), boxShadow: AppTheme.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: tcBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
          child: Row(children: [
            Text(ti, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: tc)),
              Text(r.provider, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: tcBadge, borderRadius: BorderRadius.circular(8)),
              child: Text(r.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            ResRow('✅ Eligibility',  r.eligibility),
            const SizedBox(height: 8),
            ResRow('💰 Max Amount',   r.maxAmount),
            const SizedBox(height: 8),
            ResRow('⏳ Processing',   r.processingTime),
            const SizedBox(height: 8),
            ResRow('⭐ Why It Fits',  r.highlight),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launch(r.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 13),
              label: const Text('Visit Official Website'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tc, side: BorderSide(color: tc),
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<DisplayResource> resources;
  const _ComparisonTable({required this.resources});

  @override
  Widget build(BuildContext context) {
    final headers = ['', ...resources.map((r) => r.name)];
    final rows = [
      ['Type',        ...resources.map((r) => r.type)],
      ['Provider',    ...resources.map((r) => r.provider)],
      ['Max Amount',  ...resources.map((r) => r.maxAmount)],
      ['Processing',  ...resources.map((r) => r.processingTime)],
      ['Eligibility', ...resources.map((r) => r.eligibility)],
      ['Why It Fits', ...resources.map((r) => r.highlight)],
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.border), boxShadow: AppTheme.cardShadow),
      child: ClipRRect(
        borderRadius: AppTheme.radiusMd,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Table(
              border: TableBorder(
                horizontalInside: const BorderSide(color: _kBorderFaint, width: 0.8),
                verticalInside:   const BorderSide(color: _kBorderFaint, width: 0.8),
              ),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF0F4FF)),
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(h,
                        textAlign: h.isEmpty ? TextAlign.left : TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppTheme.blue)),
                  )).toList(),
                ),
                ...rows.map((row) => TableRow(
                  children: row.asMap().entries.map((e) {
                    final isLabel = e.key == 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      child: Text(e.value,
                          textAlign: isLabel ? TextAlign.left : TextAlign.center,
                          style: TextStyle(fontSize: 11,
                              fontWeight: isLabel ? FontWeight.w700 : FontWeight.w500,
                              color: isLabel ? AppTheme.textPrimary : AppTheme.textMuted)),
                    );
                  }).toList(),
                )),
                TableRow(children: [
                  const Padding(padding: EdgeInsets.all(10),
                      child: Text('Apply', style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
                  ...resources.map((r) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => _launch(r.url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.bluePale,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('🔗 Open', textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.blue)),
                      ),
                    ),
                  )),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteBtn extends StatelessWidget {
  final bool allDone;
  final int checkedCount, total, xpReward;
  final VoidCallback onComplete;
  const _CompleteBtn({required this.allDone, required this.checkedCount,
      required this.total, required this.xpReward, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allDone ? onComplete : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.green,
          disabledBackgroundColor: AppTheme.border,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
          elevation: allDone ? 4 : 0,
        ),
        child: Text(
          allDone
              ? '✅ Complete & Earn $xpReward XP'
              : 'Complete all steps to unlock ($checkedCount/$total)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
              color: allDone ? Colors.white : AppTheme.textMuted),
        ),
      ),
    );
  }
}
