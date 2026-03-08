// ─── SOS Guidance Card ────────────────────────────────────────────────────────
// The orange "Stuck? Get AI Guidance" button
import 'package:companyenchancer/model/app_theme.dart';
import 'package:flutter/material.dart';

class SosGuidanceCard extends StatelessWidget {
  final String location;
  final VoidCallback onTap;

  const SosGuidanceCard({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x1AFF9800), // _kOrangeBg
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x66FF9800)), // _kOrangeBorder
        ),
        child: Row(
          children: [
            const Text('🆘', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stuck? Get AI Guidance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    'Nexus AI will walk you through each action step-by-step for $location.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Micro Task Item ──────────────────────────────────────────────────────────
// The individual checkbox row (Locked / Unlocked / Done)
class MicroTaskItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isDone;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const MicroTaskItem({
    super.key,
    required this.index,
    required this.text,
    required this.isDone,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Local colors for self-containment
    const kGray50 = Color(0xFFF9FAFB);
    const kGray200 = Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone 
              ? AppTheme.greenPale 
              : isUnlocked ? Colors.white : kGray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone 
                ? AppTheme.green 
                : isUnlocked ? AppTheme.blue : AppTheme.border,
            width: isDone || isUnlocked ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number / Checkmark Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26, 
              height: 26,
              decoration: BoxDecoration(
                color: isDone 
                    ? AppTheme.green 
                    : isUnlocked ? Colors.white : kGray200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone 
                      ? AppTheme.green 
                      : isUnlocked ? AppTheme.blue : AppTheme.border,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                  : !isUnlocked
                      ? const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 13)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.blue,
                            ),
                          ),
                        ),
            ),
            const SizedBox(width: 12),
            // Task Text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: isUnlocked && !isDone ? FontWeight.w600 : FontWeight.w500,
                  color: isDone 
                      ? AppTheme.green 
                      : isUnlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: AppTheme.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}