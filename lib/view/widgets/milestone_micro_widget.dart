import 'package:flutter/material.dart';
import '../../model/app_theme.dart'; // Adjust this path if your AppTheme is elsewhere

// Local constant needed for InfoChip
const _kWhite15 = Color(0x26FFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
// Shared micro-widgets (Public)
// ─────────────────────────────────────────────────────────────────────────────

class ResRow extends StatelessWidget {
  final String label, value;
  const ResRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 120, child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: AppTheme.textMuted))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary, height: 1.4))),
    ],
  );
}

class InfoChip extends StatelessWidget {
  final String label;
  const InfoChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: const BoxDecoration(
      color: _kWhite15,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    child: Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 1, color: AppTheme.textMuted));
}