// lib/view/milestone_detail_screen.dart
import 'package:companyenchancer/controller/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/milestone_model.dart';
import '../model/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MilestoneDetailScreen extends ConsumerStatefulWidget {
  final MilestoneModel milestone;
  final VoidCallback? onComplete;

  const MilestoneDetailScreen({
    super.key,
    required this.milestone,
    this.onComplete,
  });

  @override
  ConsumerState<MilestoneDetailScreen> createState() => _MilestoneDetailScreenState();
}

class _MilestoneDetailScreenState extends ConsumerState<MilestoneDetailScreen> {
  late int _currentStep;
  final Set<int> _checkedSteps = {};

  @override
  void initState() {
    super.initState();
    _currentStep = widget.milestone.currentStep;
    for (int i = 0; i < _currentStep; i++) {
      _checkedSteps.add(i);
    }
    _currentStep = widget.milestone.currentStep;
  }

  void _updateProgress() {
    int consecutive = 0;
    // Count how many steps are checked in a row starting from 0
    for (int i = 0; i < widget.milestone.steps.length; i++) {
      if (_checkedSteps.contains(i)) {
        consecutive++;
      } else {
        break; // Stop counting at the first unchecked step
      }
    }
    
      _currentStep = consecutive;

  }

  bool get _allDone => _checkedSteps.length == widget.milestone.steps.length;


void _handleStepTap(int index, String stepName) {
    if (_checkedSteps.contains(index)) {
      // If already checked, just uncheck it directly
      setState(() {
        _checkedSteps.remove(index);
        _updateProgress();
      });
    } else {
      // If unchecked, REQUIRE VALIDATION
      _showVerificationDialog(index, stepName);
    }
  }

  void _showVerificationDialog(int index, String stepName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('⚠️ Verify Completion'),
        content: Text(
          'Have you actually completed "$stepName"?\n\n'
          'Real growth happens when you do the work, not just click the box.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _openChatHelp(stepName);
            },
            child: const Text('🆘 I\'m Stuck / Need Help', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _checkedSteps.add(index);
                _updateProgress();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
            child: const Text('Yes, I did it'),
          ),
        ],
      ),
    );
  }

  void _openChatHelp(String stepName) {
    // 3. USAGE: 'ref' is available because we extended ConsumerState
    ref.read(chatControllerProvider.notifier).sendMessage(
        "I am stuck on this step: \"$stepName\". Can you give me a step-by-step guide or a challenge to help me get it done?");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating help... Open the Chatbot 💬 to see your guide!'),
        backgroundColor: AppTheme.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          m.weekLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Hero ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: AppTheme.radiusLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  Text(
                    m.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip('⏱ ${m.estimatedTime}'),
                      const SizedBox(width: 8),
                      _InfoChip('⭐ +${m.xpReward} XP'),
                      const SizedBox(width: 8),
                      _InfoChip('🛠 ${m.tool}'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Steps ─────────────────────────────────────────────────
            const _SectionLabel('YOUR ACTION STEPS'),
            const SizedBox(height: 12),

            ...m.steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isChecked = _checkedSteps.contains(i);
              final isLocked = i > _currentStep;

            return GestureDetector(
              onTap: isLocked 
      ? null  
      : () => _handleStepTap(i, step),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppTheme.greenPale
                        : Colors.white,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: isChecked
                          ? AppTheme.green
                          : AppTheme.border,
                      width: isChecked ? 1.5 : 1,
                    ),
                    boxShadow: isChecked ? [] : AppTheme.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step number or check
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isChecked
                            ? Container(
                                key: const ValueKey('check'),
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppTheme.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : Container(
                                key: ValueKey('num_$i'),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: isChecked
                                ? AppTheme.green
                                : AppTheme.textPrimary,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── Tool Card ──────────────────────────────────────────────
            if (m.tool.isNotEmpty) ...[
              const _SectionLabel('RECOMMENDED TOOL'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.bluePale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('🛠', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.tool,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (m.toolUrl.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.toolUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Open button — only shown if URL exists
                    if (m.toolUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                          final uri = Uri.parse(m.toolUrl);
                          try {
                          if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                        } catch (e) {
                        debugPrint('Could not launch url: $e');
                      }
                       // Mark current step done when user returns from tool
                      setState(() {
                      _checkedSteps.add(_currentStep);
                      _updateProgress();
                      });
},
                          icon: const Icon(Icons.open_in_new_rounded, size: 15),
                          label: Text('Open ${m.tool}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.blue,
                            side: const BorderSide(color: AppTheme.blue),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.radiusSm,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Source Validation ──────────────────────────────────────
            if (m.source.isNotEmpty) ...[
              const _SectionLabel('WHY THIS WORKS'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📚', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          m.source,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.sourceInsight,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // ── Complete Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allDone
                    ? () {
                        widget.onComplete?.call();
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  disabledBackgroundColor: AppTheme.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.radiusMd,
                  ),
                  elevation: _allDone ? 4 : 0,
                ),
                child: Text(
                  _allDone
                      ? '✅ Complete & Earn ${m.xpReward} XP'
                      : 'Complete all steps to unlock (${_checkedSteps.length}/${m.steps.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _allDone ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: AppTheme.textMuted,
      ),
    );
  }
}