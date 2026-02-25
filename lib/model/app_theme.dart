// lib/model/app_theme.dart
import 'package:flutter/material.dart';

/// Centralised design tokens for ASEAN Nexus.
/// Import this file anywhere you need brand colours or text styles.
class AppTheme {
  AppTheme._();

  // ── Brand Colours ──────────────────────────────────────────────────────────
  static const Color green        = Color(0xFF2E7D32);
  static const Color greenLight   = Color(0xFF43A047);
  static const Color greenDark    = Color(0xFF1B5E20);
  static const Color greenPale    = Color(0xFFE8F5E9);

  static const Color blue         = Color(0xFF1565C0);
  static const Color blueLight    = Color(0xFF1976D2);
  static const Color bluePale     = Color(0xFFE3F2FD);

  static const Color gold         = Color(0xFFF59E0B);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color background   = Color(0xFFF5F7FA);
  static const Color textPrimary  = Color(0xFF1A1A2E);
  static const Color textMuted    = Color(0xFF6B7280);
  static const Color border       = Color(0xFFE5E7EB);
  static const Color error        = Color(0xFFDC2626);

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> greenGlow(double opacity) => [
        BoxShadow(
          color: green.withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> blueGlow(double opacity) => [
        BoxShadow(
          color: blue.withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [greenDark, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [green, greenLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Border Radius ──────────────────────────────────────────────────────────
  static const BorderRadius radiusSm  = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd  = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusLg  = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusXl  = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(28));
}
