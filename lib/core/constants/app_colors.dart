import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color backgroundPrimary = Color(0xFF0A0A14);
  static const Color backgroundCard = Color(0xFF12132A);
  static const Color backgroundSurface = Color(0xFF1A1B3A);

  // Accents
  static const Color accentBlue = Color(0xFF4D9EFF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Semantics
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted = Color(0xFF4A5568);

  // Card Gradients (Galaxy themes - Index 0 is reserved for Membership Red)
  static const List<List<Color>> cardGradients = [
    [Color(0xFF7F1D1D), Color(0xFFEF4444)], // 0: Crimson Red (Reserved)
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // 1: Blue galaxy
    [Color(0xFF4C1D95), Color(0xFF8B5CF6)], // 2: Purple nebula
    [Color(0xFF0C4A6E), Color(0xFF06B6D4)], // 3: Cyan deep
    [Color(0xFF1E1B4B), Color(0xFF6366F1)], // 4: Indigo cosmos
    [Color(0xFF134E4A), Color(0xFF10B981)], // 5: Teal aurora
    [Color(0xFF701A75), Color(0xFFD946EF)], // 6: Fuchsia flare
    [Color(0xFF431407), Color(0xFFF97316)], // 7: Orange ember
    [Color(0xFF064E3B), Color(0xFF34D399)], // 8: Emerald wave
    [Color(0xFF1E293B), Color(0xFF94A3B8)], // 9: Slate shadow
    [Color(0xFF312E81), Color(0xFF818CF8)], // 10: Violet starlight
  ];
}
