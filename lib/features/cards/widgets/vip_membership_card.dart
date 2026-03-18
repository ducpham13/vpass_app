import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/card_model.dart';

class VipMembershipCard extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onTap;
  final String? statusBadge;

  const VipMembershipCard({
    super.key,
    required this.card,
    this.onTap,
    this.statusBadge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A11CB), // Deep Purple
              Color(0xFF2575FC), // Vibrant Blue
              Color(0xFF1CB5E0), // Cyan
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A11CB).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Abstract Star Background Pattern
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.star,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 120,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEMBERSHIP',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                                SizedBox(width: 4),
                                Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                                SizedBox(width: 4),
                                Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusBadge != null ? Colors.black26 : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusBadge != null ? Colors.white38 : Colors.white24),
                          ),
                          child: Text(
                            statusBadge ?? 'VPASS VIP',
                            style: TextStyle(
                              color: statusBadge != null ? Colors.white : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Days remaining countdown
                    Builder(builder: (_) {
                      final daysLeft = card.endDate.difference(DateTime.now()).inDays;
                      final daysText = daysLeft < 0 ? 'Hết hạn' : 'Còn $daysLeft ngày';
                      return Text(
                        daysText,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: daysLeft <= 3 ? const Color(0xFFFF6B6B) : Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      );
                    }),
                    const SizedBox(height: 2),
                    Text(
                      statusBadge != null 
                        ? 'TRẠNG THÁI: ${statusBadge!.toUpperCase()}' 
                        : 'HẾT HẠN: ${DateFormat('dd/MM/yyyy').format(card.endDate)}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SỬ DỤNG TOÀN HỆ THỐNG',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
