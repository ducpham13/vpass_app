import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../admin_provider.dart';

class TotalRevenueScreen extends ConsumerStatefulWidget {
  const TotalRevenueScreen({super.key});

  @override
  ConsumerState<TotalRevenueScreen> createState() => _TotalRevenueScreenState();
}

class _TotalRevenueScreenState extends ConsumerState<TotalRevenueScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final stats = statsAsync.value ?? AdminStats();

    final formatter = NumberFormat('#,###', 'vi_VN');

    final totalRevenue = stats.mtdRevenue;
    final regularRevenue = stats.totalRegularRevenue;
    final vipRevenue = stats.totalVipRevenue;

    final regularGymPayout = stats.regularGymPayout;
    final vipGymPayout = stats.vipGymPayout;

    final regularPct = totalRevenue > 0
        ? (regularRevenue / totalRevenue) * 100
        : 0.0;
    final vipPct = totalRevenue > 0 ? (vipRevenue / totalRevenue) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Tổng Doanh Thu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 32),

            // Total Revenue
            Center(
              child: Text(
                '${formatter.format(totalRevenue)}đ',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'CHI TIẾT THEO LOẠI THẺ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.confirmation_number,
                    iconColor: AppColors
                        .accentBlue, // Use warning if you want exactly like screenshot, but screenshot looks blueish for regular or maybe different. Screenshot: Regular has a ticket icon, goldish color for icon but text is white. Waiting for exact color, I will use AppColors.warning for ticket icon as in Platform Profit.
                    iconColorCustom: const Color(
                      0xFFFACC15,
                    ), // Gold/Yellow for Regular ticket
                    title: 'Regular',
                    amount: regularRevenue,
                    percentage: regularPct,
                    formatter: formatter,
                  ),
                  Divider(
                    color: AppColors.textMuted.withOpacity(0.3),
                    height: 1,
                  ),
                  _buildDetailRow(
                    icon: Icons.star,
                    iconColor: AppColors.accentPurple,
                    iconColorCustom: const Color(
                      0xFFFACC15,
                    ), // Star is also Goldish
                    title: 'VIP',
                    amount: vipRevenue,
                    percentage: vipPct,
                    formatter: formatter,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỶ LỆ ĐÓNG GÓP',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProgressRow(
                    'Regular',
                    AppColors.accentBlue,
                    regularPct,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressRow('VIP', AppColors.accentPurple, vipPct),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'PAYOUT CHO GYM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildPayoutRow(
                    icon: Icons.fitness_center,
                    title: 'Từ thẻ thường',
                    amount: regularGymPayout,
                    subtitle: '',
                    formatter: formatter,
                  ),
                  Divider(
                    color: AppColors.textMuted.withOpacity(0.3),
                    height: 1,
                  ),
                  _buildPayoutRow(
                    icon: Icons.fitness_center,
                    title: 'Từ thẻ VIP',
                    amount: vipGymPayout,
                    subtitle: '',
                    formatter: formatter,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          Text(
            'Tháng ${_selectedDate.month} / ${_selectedDate.year}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    Color? iconColorCustom,
    required String title,
    required double amount,
    required double percentage,
    required NumberFormat formatter,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColorCustom ?? iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(amount)}đ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, Color color, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 45,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRow({
    required IconData icon,
    required String title,
    required double amount,
    required String subtitle,
    required NumberFormat formatter,
  }) {
    // Determine color based on title to match screenshot (Blue for Regular, Purple for VIP)
    final isRegular = title.contains('thường');
    final amountColor = isRegular
        ? AppColors.accentBlue
        : AppColors.accentPurple;
    final iconColor = const Color(
      0xFFFACC15,
    ); // Yellowish color for the dumbbell icon like screenshot

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(amount)}đ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
