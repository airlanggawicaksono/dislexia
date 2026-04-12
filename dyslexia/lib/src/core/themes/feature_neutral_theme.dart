import 'package:flutter/material.dart';

class FeatureNeutralTheme {
  FeatureNeutralTheme._();

  static const background = Color(0xFFF5F0E8);
  static const surface = Color(0xFFEFEADF);
  static const surfaceStrong = Color(0xFFE4DDD1);
  static const border = Color(0xFFD8CFBF);
  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF5E5A53);
  static const accent = Color(0xFF4C658A);
  static const overlayDark = Color(0x55000000);

  static BoxDecoration panelDecoration() => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      );

  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
}
