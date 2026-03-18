import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/card_model.dart';
import 'package:intl/intl.dart';

class AtmCardWidget extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;
  
  const AtmCardWidget({
    super.key,
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 5 random colors available in AppColors.cardGradients
    final presetColors = AppColors.cardGradients[card.colorIndex % AppColors.cardGradients.length];
    
    final isExpired = card.isExpired;
    final gradientColors = isExpired 
        ? [Colors.grey.shade800, Colors.grey.shade900]
        : presetColors;
        
    final remainingDays = card.endDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Inner glow simulation geometric pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card.isMembership ? 'MEMBERSHIP' : 'SINGLE PASS',
                        style: AppTextStyles.labelLarge.copyWith(letterSpacing: 2),
                      ),
                      if (isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'EXPIRED',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$remainingDays Days Left',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.isMembership ? 'Partner Gym Network' : 'Specific Gym Name',
                        style: AppTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Exp: ${DateFormat('MM/dd/yyyy').format(card.endDate)}",
                        style: AppTextStyles.monoMedium.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
