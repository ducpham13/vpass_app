import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class GalaxyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final Color baseColor;

  const GalaxyButton({
    super.key,
    this.onPressed,
    required this.text,
    this.isLoading = false,
    this.baseColor = AppColors.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || onPressed == null;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: baseColor.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
        gradient: LinearGradient(
          colors: isDisabled
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [baseColor.withOpacity(0.8), baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
