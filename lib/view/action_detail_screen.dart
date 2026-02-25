// lib/view/action_detail_screen.dart
// Hero animation destination for the "Next Best Action" card.

import 'package:flutter/material.dart';
import '../model/app_theme.dart';

class ActionDetailScreen extends StatelessWidget {
  const ActionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Hero(
        tag: 'next-best-action',
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Hero header (gradient card)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: AppTheme.radiusXl,
                    boxShadow: AppTheme.greenGlow(0.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text("TODAY'S WORKOUT",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload 3 months of receipts to unlock your Credit Profile',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What to do', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      const SizedBox(height: 16),
                      ..._steps.map((s) => _StepTile(step: s)),
                      const SizedBox(height: 20),
                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Upload Receipts Now →'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _steps = [
    (icon: '📸', title: 'Photograph receipts', desc: 'Take clear photos of all receipts for the past 3 months.'),
    (icon: '📤', title: 'Upload to Nexus', desc: 'Use the upload button below — we accept JPG, PNG and PDF.'),
    (icon: '🤖', title: 'AI auto-categorises', desc: 'Our AI will sort your expenses into categories automatically.'),
    (icon: '🏦', title: 'Credit profile unlocked', desc: 'Your financial score is generated and shared with 3 lenders.'),
  ];
}

class _StepTile extends StatelessWidget {
  final ({String icon, String title, String desc}) step;
  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Text(step.icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(step.desc, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
