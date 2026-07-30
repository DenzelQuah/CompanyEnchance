// lib/view/survey_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/survey_controller.dart';
import '../model/survey_model.dart';
import '../model/app_theme.dart';
import 'main_shell.dart';

class SurveyScreen extends ConsumerWidget {
  const SurveyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyControllerProvider);
    final ctrl  = ref.read(surveyControllerProvider.notifier);

    // Navigate when survey is complete
    ref.listen(surveyControllerProvider, (_, next) {
      if (next.isComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Header ──────────────────────────────────────────────
            _SurveyHeader(state: state),
            // ── Question Body ────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildQuestion(context, ref, state, ctrl),
              ),
            ),
            // ── Navigation Buttons ───────────────────────────────────────────
            _SurveyNavBar(state: state, ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    WidgetRef ref,
    SurveyModel state,
    SurveyController ctrl,
  ) {
    switch (state.currentStep) {
      case 0:  return _Q1BusinessProfile(state: state, ctrl: ctrl);
      case 1:  return _Q2Location(state: state, ctrl: ctrl);
      case 2:  return _Q3SalesTracking(state: state, ctrl: ctrl);
      case 3:  return _Q4TeamSize(state: state, ctrl: ctrl);
      case 4:  return _Q5PrimaryGoal(state: state, ctrl: ctrl);
      case 5:  return _Q6Financial(state: state, ctrl: ctrl);
      case 6:  return _Q7DigitalPresence(state: state, ctrl: ctrl);
      case 7:  return _Q8SupplyChain(state: state, ctrl: ctrl);
      case 8:  return _Q9Commitment(state: state, ctrl: ctrl);
      case 9:  return _Q10Budget(state: state, ctrl: ctrl);
      default: return const SizedBox.shrink();
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _SurveyHeader extends StatelessWidget {
  final SurveyModel state;
  const _SurveyHeader({required this.state});

  static const _stepTags = [
    'Business Profile', 'Location', 'Maturity Level', 'Team Size',
    'Business Goal', 'Financial Visibility', 'Digital Presence',
    'Supply Chain', 'Commitment Level', 'Budget',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppTheme.border,
              valueColor: const AlwaysStoppedAnimation(AppTheme.green),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${state.currentStep + 1} of ${SurveyModel.totalSteps} · ${_stepTags[state.currentStep]}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────

class _SurveyNavBar extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _SurveyNavBar({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isLast = state.currentStep == SurveyModel.totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [


          //Error Message Display
            if (state.errorMessage.isNotEmpty) ...[
            Container(
              width: double.infinity, // 1. Force container to take full width
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEEBC8), 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFBD38D)),
              ),
              child: Row(
                // 2. Removed centering, let it naturally align left
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFC53030), size: 20),
                  const SizedBox(width: 10),
                  Expanded( // 3. Use Expanded instead of Flexible
                    child: Text(
                      state.errorMessage,
                      style: const TextStyle(
                        color: Color(0xFFC53030),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],


          // Hide back button during submission
          Row(
            children: [
              if (state.currentStep > 0 && !state.isSubmitting)
                OutlinedButton(
                  onPressed: ctrl.prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    side: const BorderSide(color: AppTheme.border, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                  ),
                  child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ),
              if (state.currentStep > 0 && !state.isSubmitting) const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : ctrl.nextStep,
                    child: state.isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white, 
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(isLast ? 'Build My Roadmap 🚀' : 'Continue →'),
                  ),
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QUESTION WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _QHeader extends StatelessWidget {
  final String tag;
  final String title;
  final String subtitle;
  const _QHeader({required this.tag, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(20)),
          child: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.green, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary, height: 1.3, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final bool selected;
  final String icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.selected,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.greenPale : Colors.white,
          border: Border.all(color: selected ? AppTheme.green : AppTheme.border, width: 2),
          borderRadius: AppTheme.radiusLg,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: selected ? AppTheme.green : AppTheme.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.green : Colors.transparent,
                border: Border.all(color: selected ? AppTheme.green : AppTheme.border, width: 2),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 12) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final String text;
  const _AiBubble({required this.text, required ValueKey<String> key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)]),
        border: Border.all(color: const Color(0xFFBBDEFB)),
        borderRadius: AppTheme.radiusLg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.blue, Color(0xFF7B1FA2)]),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A237E), height: 1.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Q1: Business Profile ─────────────────────────────────────────────────────

class _Q1BusinessProfile extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q1BusinessProfile({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'BUSINESS PROFILE', title: 'Tell us about\nyour business', subtitle: 'This helps us personalise your roadmap.'),
        const Text('BUSINESS NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: state.businessName,
          onChanged: ctrl.updateBusinessName,
          decoration: const InputDecoration(hintText: 'e.g. Razif Food Tech'),
        ),
        const SizedBox(height: 16),
        const Text('SECTOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: state.sector.isEmpty ? null : state.sector,
          onChanged: (v) => ctrl.updateSector(v ?? ''),
          decoration: const InputDecoration(hintText: 'Select your sector…'),
          items: kSectors.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q2: Location ─────────────────────────────────────────────────────────────

class _Q2Location extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q2Location({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'LOCATION', title: 'Where are you based?', subtitle: 'Select your primary operating location.'),
        ...LocationOption.all.map((loc) => _OptionCard(
          selected: state.location == loc.name,
          icon: loc.flag,
          label: loc.name,
          onTap: () => ctrl.updateLocation(loc.name),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q3: Sales Tracking ───────────────────────────────────────────────────────

class _Q3SalesTracking extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q3SalesTracking({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'MATURITY LEVEL', title: 'How do you track your sales?', subtitle: "Be honest — there's no wrong answer!"),
        ...SalesTracking.values.map((t) => _OptionCard(
          selected: state.salesTracking == t,
          icon: t.icon,
          label: t.label,
          subtitle: t.subtitle,
          onTap: () => ctrl.updateSalesTracking(t),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q4: Team Size ────────────────────────────────────────────────────────────

class _Q4TeamSize extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q4TeamSize({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'TEAM SIZE', title: 'How large is your team?', subtitle: 'Include full-time and part-time members.'),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CounterBtn(icon: Icons.remove, onTap: ctrl.decrementTeamSize),
                  const SizedBox(width: 24),
                  Text(
                    '${state.teamSize}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 24),
                  _CounterBtn(icon: Icons.add, onTap: ctrl.incrementTeamSize),
                ],
              ),
              const SizedBox(height: 8),
              const Text('team members', style: TextStyle(fontSize: 14, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border, width: 2),
          borderRadius: AppTheme.radiusMd,
          color: Colors.white,
        ),
        child: Icon(icon, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ─── Q5: Primary Goal ─────────────────────────────────────────────────────────

class _Q5PrimaryGoal extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q5PrimaryGoal({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'BUSINESS GOAL', title: 'What is your primary goal?', subtitle: 'Choose the one that excites you most.'),
        ...PrimaryGoal.values.map((g) => _OptionCard(
          selected: state.primaryGoal == g,
          icon: g.icon,
          label: g.label,
          subtitle: g.subtitle,
          onTap: () => ctrl.updatePrimaryGoal(g),
        )),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.showExportInsight
              ? const _AiBubble(
                  key: ValueKey('export-insight'),
                  text: "Great goal! We'll tailor your roadmap for cross-border logistics and help you navigate ASEAN trade regulations.",
                )
              : const SizedBox.shrink(key: ValueKey('no-insight')),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q6: Financial Visibility ─────────────────────────────────────────────────

class _Q6Financial extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q6Financial({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(
          tag: 'FINANCIAL VISIBILITY',
          title: 'Do you have audited financial statements?',
          subtitle: 'Required for most formal financing options.',
        ),
        GestureDetector(
          onTap: ctrl.toggleAuditedStatements,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border, width: 2),
              borderRadius: AppTheme.radiusLg,
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Audited Financial Statements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Formal audit by certified accountant', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                // Toggle switch
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 48, height: 28,
                  decoration: BoxDecoration(
                    color: state.hasAuditedStatements ? AppTheme.green : AppTheme.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    alignment: state.hasAuditedStatements ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22, height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.background, borderRadius: AppTheme.radiusMd),
          child: Text(
            state.hasAuditedStatements
                ? '✅ Great! Audited statements unlock preferential financing rates and investor credibility.'
                : "💡 No audit yet? No worries. We'll guide you through simplified bookkeeping as your first milestone.",
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.6),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q7: Digital Presence ─────────────────────────────────────────────────────

class _Q7DigitalPresence extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q7DigitalPresence({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'DIGITAL PRESENCE', title: 'Where are you selling online?', subtitle: 'Select all that apply.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DigitalPlatform.all.map((p) {
            final selected = state.digitalPresence.contains(p.name);
            return GestureDetector(
              onTap: () => ctrl.toggleDigitalPlatform(p.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.greenPale : Colors.white,
                  border: Border.all(color: selected ? AppTheme.green : AppTheme.border, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.icon),
                    const SizedBox(width: 6),
                    Text(p.name, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? AppTheme.green : AppTheme.textPrimary,
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q8: Supply Chain ─────────────────────────────────────────────────────────

class _Q8SupplyChain extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q8SupplyChain({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'SUPPLY CHAIN', title: 'Describe your supply chain', subtitle: 'Helps us assess your export readiness.'),
        ...SupplyChain.values.map((s) => _OptionCard(
          selected: state.supplyChain == s,
          icon: s.icon,
          label: s.label,
          subtitle: s.subtitle,
          onTap: () => ctrl.updateSupplyChain(s),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q9: Commitment ───────────────────────────────────────────────────────────

class _Q9Commitment extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q9Commitment({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'COMMITMENT LEVEL', title: 'How committed are you?', subtitle: 'How many hours per week can you dedicate?'),
        ...WeeklyCommitment.values.map((c) => _OptionCard(
          selected: state.weeklyCommitment == c,
          icon: c.icon,
          label: c.label,
          subtitle: c.subtitle,
          onTap: () => ctrl.updateWeeklyCommitment(c),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Q10: Budget ──────────────────────────────────────────────────────────────

class _Q10Budget extends StatelessWidget {
  final SurveyModel state;
  final SurveyController ctrl;
  const _Q10Budget({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _QHeader(tag: 'BUDGET', title: 'What is your growth budget?', subtitle: "Be realistic — both paths lead to success!"),
        ...BudgetPlan.values.map((b) => _OptionCard(
          selected: state.budgetPlan == b,
          icon: b.icon,
          label: b.label,
          subtitle: b.subtitle,
          onTap: () => ctrl.updateBudgetPlan(b),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}
