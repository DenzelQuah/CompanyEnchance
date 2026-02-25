// lib/view/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';
import '../controller/survey_controller.dart';
import '../model/survey_model.dart';
import '../model/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState             = ref.watch(authControllerProvider);
    // ✅ Explicitly typed — fixes NoSuchMethodError: getter called on null
    final SurveyModel surveyState = ref.watch(surveyControllerProvider);
    final int score             = ref.read(surveyControllerProvider.notifier).readinessScore;

    final String name  = authState.userName  ?? 'Ahmad Razif';
    final String email = authState.userEmail ?? 'ahmad@example.com';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(name: name, email: email, score: score),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Business summary card
                _BusinessSummaryCard(surveyState: surveyState),
                const SizedBox(height: 12),
                // Settings section
                _Section(children: [
                  _SettingsRow(icon: '🔔', bg: const Color(0xFFFEF3C7), label: 'Notifications', value: 'Daily'),
                  _SettingsRow(icon: '🌐', bg: const Color(0xFFF0FDF4), label: 'Language', value: 'English'),
                  _SettingsRow(icon: '🤝', bg: const Color(0xFFEFF6FF), label: 'Find Mentor', value: 'Match me'),
                  _SettingsRow(icon: '💰', bg: const Color(0xFFFDF4FF), label: 'Funding Explorer', value: '3 options'),
                ]),
                const SizedBox(height: 12),
                // Sign out
                _Section(children: [
                  _SettingsRow(
                    icon: '🚪',
                    bg: const Color(0xFFFEF2F2),
                    label: 'Sign Out',
                    labelColor: AppTheme.error,
                    onTap: () {
                      ref.read(authControllerProvider.notifier).signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final int score;

  const _ProfileHero({required this.name, required this.email, required this.score});

  static const _badges = ['🌱', '📋', '📱', '🌍', '💎'];
  static const _earnedCount = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.radiusXl,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: const Center(child: Text('🧑‍💼', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _badges.asMap().entries.map((e) {
              final earned = e.key < _earnedCount;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(earned ? 0.15 : 0.05),
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: Colors.white.withOpacity(earned ? 0.4 : 0.15)),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: TextStyle(fontSize: 20, color: earned ? null : Colors.white30),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⭐ Readiness Score: $score / 100',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Business Summary Card ────────────────────────────────────────────────────

class _BusinessSummaryCard extends StatelessWidget {
  // ✅ Strongly typed — was `final surveyState;` (dynamic) which caused the crash
  final SurveyModel surveyState;

  const _BusinessSummaryCard({required this.surveyState});

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> rows = [
      ('Business Name', surveyState.businessName.isEmpty ? '—' : surveyState.businessName),
      ('Sector',        surveyState.sector.isEmpty       ? '—' : surveyState.sector),
      ('Location',      surveyState.location.isEmpty     ? '—' : surveyState.location),
      ('Team Size',     '${surveyState.teamSize} people'),
      ('Primary Goal',  surveyState.primaryGoal?.label   ?? '—'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BUSINESS PROFILE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  Text(r.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Section Container ───────────────────────────────────────────────

class _Section extends StatelessWidget {
  final List<Widget> children;
  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusLg,
        child: Column(
          children: List.generate(children.length, (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1) const Divider(height: 1, indent: 64),
            ],
          )),
        ),
      ),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final String       icon;
  final Color        bg;
  final String       label;
  final String?      value;
  final Color?       labelColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.bg,
    required this.label,
    this.value,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: AppTheme.radiusSm),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            if (value != null) ...[
              Text(value!, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}