import 'package:flutter/material.dart';

/// MedTrack design token colors — pharmacy green identity
class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFF0F7B3E);
  static const Color primaryTint = Color(0xFFE6F4EA);
  static const Color primaryDark = Color(0xFF095C2C);
  static const Color primaryLight = Color(0xFF3DA563);

  // Background
  static const Color background = Color(0xFFF6FBF7);
  static const Color surface = Color(0xFFFFFFFF);

  // Danger / Due
  static const Color dangerBg = Color(0xFFFDE8E8);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerLight = Color(0xFFEF5350);

  // Warning / Expiry
  static const Color warnBg = Color(0xFFFFF3D6);
  static const Color warn = Color(0xFFB26A00);

  // Info / Backup
  static const Color infoBg = Color(0xFFE3F0FF);
  static const Color info = Color(0xFF1E5FBF);

  // Success
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);

  // Neutral
  static const Color charcoal = Color(0xFF263238);
  static const Color grey700 = Color(0xFF455A64);
  static const Color grey500 = Color(0xFF667085);
  static const Color grey300 = Color(0xFFCFD8DC);
  static const Color grey100 = Color(0xFFECEFF1);
  static const Color border = Color(0xFFE7EFE9);

  // Avatar palette for initials
  static const List<Color> avatarColors = [
    Color(0xFF0F7B3E),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFFB26A00),
    Color(0xFF00695C),
    Color(0xFF283593),
    Color(0xFF4A148C),
  ];
}
