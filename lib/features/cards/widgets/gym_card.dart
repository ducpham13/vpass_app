import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/gym_model.dart';
import '../../../shared/glass_container.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GymCard extends StatelessWidget {
  final GymModel gym;
  final VoidCallback onTap;
  final bool showOperationalInfo;
  final String? customBadgeText;
  final bool useSolidColor;
  final double? currentCardUsage; // For membership
  final double? cardPrice; // For membership

  const GymCard({
    super.key,
    required this.gym,
    required this.onTap,
    this.showOperationalInfo = true,
    this.customBadgeText,
    this.useSolidColor = false,
    this.currentCardUsage,
    this.cardPrice,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status text and color
    final bool isOpen = !gym.isClosedOverride;
    final String statusText = isOpen ? 'Đang mở cửa' : 'Đóng cửa hôm nay';
    final Color statusColor = isOpen ? AppColors.success : AppColors.danger;
    final String hoursText = isOpen
        ? '${gym.openTime} – ${gym.closeTime}'
        : '(thường ${gym.openTime} – ${gym.closeTime})';
    final brandGradient = AppColors
        .cardGradients[gym.colorIndex % AppColors.cardGradients.length];
    final navyBg = const Color(0xFF15192C);

    if (useSolidColor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              // 1. TOP BRAND BAR (Gym Name)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: brandGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Text(
                  gym.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // NEW: Image Header (Responsive) - Below the Name Bar as requested
              if (gym.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: gym.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    height: 100,
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              // 2. NAVY BODY
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: navyBg,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge (Remaining Days) - Floating top right style
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${gym.address}, ${gym.city}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2442),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            customBadgeText ?? '',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.accentBlue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (showOperationalInfo) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      // Today's Status Section
                      Text(
                        'TÌNH TRẠNG HÔM NAY',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white38,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hoursText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCrowdLevel(),

                      if (currentCardUsage != null && cardPrice != null) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SỬ DỤNG',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              '${((currentCardUsage! / (cardPrice! * 0.95)) * 100).toInt()}%',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.accentBlue,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (currentCardUsage! / (cardPrice! * 0.95)).clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                            minHeight: 4,
                          ),
                        ),
                      ],

                      // Emergency Notice (customer side)
                      if (gym.emergencyNotice != null &&
                          gym.emergencyNotice!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE57373),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  gym.emergencyNotice!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFFFCDD2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // DEFAULT MARKETPLACE VIEW
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          opacity: 0.15,
          blur: 20,
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: gym.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: gym.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.contain, // Keep original size/aspect ratio
                            placeholder: (context, url) => Container(
                              height: 160,
                              color: AppColors.accentBlue.withOpacity(0.1),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 160,
                              color: AppColors.accentBlue.withOpacity(0.1),
                              child: const Icon(Icons.error_outline),
                            ),
                          )
                        : Container(
                            height: 100,
                            width: double.infinity,
                            color: AppColors.accentBlue.withOpacity(0.1),
                          ),
                  ),
                  // Price Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        customBadgeText ??
                            '${gym.pricePerMonth.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ/th',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.accentBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Town
                    Text(gym.name, style: AppTextStyles.displaySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${gym.address}, ${gym.city}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),

                    // Today's Status
                    Text(
                      'TÌNH TRẠNG HÔM NAY',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white38,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hoursText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (showOperationalInfo) ...[
                      const SizedBox(height: 16),
                      // Crowd Level
                      _buildCrowdLevel(),

                      // Emergency Notice
                      if (gym.emergencyNotice != null &&
                          gym.emergencyNotice!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE57373),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  gym.emergencyNotice!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFFFCDD2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrowdLevel() {
    int totalBars = 3;
    int filledCount = 1;
    Color color = AppColors.success;
    String label = 'Đang vắng';

    if (gym.crowdLevel == 'average') {
      filledCount = 2;
      color = Color(0xFFFBC02D);
      label = 'Trung bình';
    } else if (gym.crowdLevel == 'busy') {
      filledCount = 3;
      color = AppColors.danger;
      label = 'Đông đúc';
    }

    return Row(
      children: [
        ...List.generate(totalBars, (index) {
          final bool isFilled = index < filledCount;
          return Container(
            width: 24,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isFilled ? color : Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
