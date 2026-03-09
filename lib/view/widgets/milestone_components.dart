import 'package:companyenchancer/services/milestone_helpers.dart';
import 'package:flutter/material.dart';
import '../../model/app_theme.dart';
import '../../model/milestone_model.dart';
import '../../model/survey_model.dart';
import 'milestone_micro_widget.dart'; // Import your shared widgets (SectionLabel)

class WhySection extends StatelessWidget {
  // changed List<_WhyPoint> to List<WhyPoint>
  final List<WhyPoint> points; 
  final MilestoneModel milestone;
  final SurveyModel survey;
  final VoidCallback onAskAi;

  const WhySection({
    super.key, 
    required this.points, 
    required this.milestone,
    required this.survey, 
    required this.onAskAi
  });

  @override
  Widget build(BuildContext context) {
    final s = survey;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Now uses the public SectionLabel from your micro-widgets file
      const SectionLabel('WHY THIS WORKS FOR YOU'),
      const SizedBox(height: 4),
      Text('Tailored to ${s.businessName} · ${s.sector} · ${s.location}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(children: [
              Text('🎯', style: TextStyle(fontSize: 14)), SizedBox(width: 8),
              Expanded(child: Text('Generated from your diagnostic answers — not generic advice.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E), height: 1.4))),
            ]),
          ),
          ...points.asMap().entries.map((entry) {
            final isLast = entry.key == points.length - 1;
            final p = entry.value;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(p.emoji,
                          style: const TextStyle(fontSize: 16)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title, style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    const SizedBox(height: 4),
                    Text(p.body, style: const TextStyle(fontSize: 12,
                        height: 1.55, color: Color(0xFF78350F))),
                  ])),
                ]),
              ),
              if (!isLast)
                const Divider(height: 1, color: Color(0xFFFDE68A), indent: 14),
            ]);
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAskAi,
                icon: const Text('🤖', style: TextStyle(fontSize: 13)),
                label: const Text('Ask AI to Explain More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFEF3C7),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusSm),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}