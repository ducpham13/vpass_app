import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../admin_provider.dart';

class PlatformProfitScreen extends ConsumerStatefulWidget {
  const PlatformProfitScreen({super.key});

  @override
  ConsumerState<PlatformProfitScreen> createState() => _PlatformProfitScreenState();
}

class _PlatformProfitScreenState extends ConsumerState<PlatformProfitScreen> {
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
    
    final totalProfit = stats.platformProfit;
    final regularProfit = stats.regularCardProfit;
    final vipProfit = stats.vipFeeProfit;
    final unusedProfit = stats.unusedVipQuotaProfit;

    final regularPct = totalProfit > 0 ? (regularProfit / totalProfit) * 100 : 0.0;
    final vipPct = totalProfit > 0 ? (vipProfit / totalProfit) * 100 : 0.0;
    final unusedPct = totalProfit > 0 ? (unusedProfit / totalProfit) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Lợi Nhuận Platform', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
            
            // Total Profit
            Center(
              child: Text(
                '${formatter.format(totalProfit)}đ',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            const Text(
              'CHI TIẾT',
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
                    iconColor: AppColors.accentBlue,
                    title: 'Thẻ thường (10%)',
                    amount: regularProfit,
                    percentage: regularPct,
                    formatter: formatter,
                  ),
                  Divider(color: AppColors.textMuted.withOpacity(0.3), height: 1),
                  _buildDetailRow(
                    icon: Icons.star,
                    iconColor: AppColors.accentPurple,
                    title: 'VIP fee (5%)',
                    amount: vipProfit,
                    percentage: vipPct,
                    formatter: formatter,
                  ),
                  Divider(color: AppColors.textMuted.withOpacity(0.3), height: 1),
                  _buildDetailRow(
                    icon: Icons.diamond,
                    iconColor: AppColors.success,
                    title: 'Unused VIP quota',
                    amount: unusedProfit,
                    percentage: unusedPct,
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
                  _buildProgressRow('Thẻ thường', AppColors.accentBlue, regularPct),
                  const SizedBox(height: 16),
                  _buildProgressRow('VIP fee', AppColors.accentPurple, vipPct),
                  const SizedBox(height: 16),
                  _buildProgressRow('Unused quota', AppColors.success, unusedPct),
                ],
              ),
            ),
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
              child: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 20),
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
              child: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
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
          width: 90,
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
}
