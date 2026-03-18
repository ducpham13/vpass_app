import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/constants/app_colors.dart';

class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavigationBarItem> items;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: items,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.accentBlue,
            unselectedItemColor: AppColors.textMuted,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }
}
