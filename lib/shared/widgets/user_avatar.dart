import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final List<Color>? gradientColors;
  final double? fontSize;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.gradientColors,
    this.fontSize,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    
    // Take first char of first word and first char of last word
    return '${parts[0].substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final colors = gradientColors ?? [const Color(0xFF4D9EFF), const Color(0xFF6366F1)];
    
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: radius * 0.4,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.labelLarge.copyWith(
            fontSize: fontSize ?? (radius * 0.8),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
