import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/glass_container.dart';
import '../../auth/auth_provider.dart';
import '../../cards/gym_provider.dart';
import '../partner_earnings_provider.dart';
import '../../../models/gym_model.dart';

class PartnerEarningsScreen extends ConsumerWidget {
  final String gymId;
  final String gymName;

  const PartnerEarningsScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsProvider(gymId));
    final paidAsync = ref.watch(paidWithdrawalsTotalProvider(gymId));
    final logsAsync = ref.watch(earningsLogsProvider(gymId));
    final gymAsync = ref.watch(gymDetailProvider(gymId));
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final earningsMap = earningsAsync.value ?? {'total': 0.0, 'available': 0.0};
    final total = earningsMap['total'] ?? 0.0;
    final available = earningsMap['available'] ?? 0.0;
    
    final paid = paidAsync.value ?? 0.0;
    final withdrawable = (available - paid).clamp(0.0, double.infinity);
    final pending = (total - available).clamp(0.0, double.infinity);
    
    final gym = gymAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('THU NHẬP - $gymName'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsProvider(gymId));
          ref.invalidate(paidWithdrawalsTotalProvider(gymId));
          ref.invalidate(earningsLogsProvider(gymId));
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Header Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildBalanceCard(withdrawable, currencyFormat, context, ref, gym),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsRow(total, paid, pending, currencyFormat),
                  ],
                ),
              ),
            ),

            // Logs Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lịch sử doanh thu', style: AppTextStyles.displaySmall),
                    const Icon(Icons.history, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            // Logs List
            logsAsync.when(
              data: (logs) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = logs[index];
                    final time = (log['timestamp'] as dynamic).toDate();
                    final timeStr = DateFormat('HH:mm - dd/MM').format(time);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (log['type'] == 'global_checkin' 
                              ? AppColors.accentCyan 
                              : AppColors.accentBlue).withOpacity(0.2),
                            child: Icon(
                              log['type'] == 'global_checkin' 
                                ? Icons.fitness_center 
                                : Icons.shopping_bag_outlined,
                              color: log['type'] == 'global_checkin' 
                                ? AppColors.accentCyan 
                                : AppColors.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['type'] == 'global_checkin' 
                                    ? 'Check-in VIP' 
                                    : 'Bán thẻ mới',
                                  style: AppTextStyles.bodyLarge,
                                ),
                                Text(
                                  '${log['buyerUid'] != null ? 'Hội viên Vpass' : ''} • $timeStr',
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+${currencyFormat.format(log['partnerEarned'] ?? log['earnedAmount'] ?? 0)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: logs.length,
                ),
              ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SliverFillRemaining(child: Center(child: Text('Lỗi: $err'))),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double available, NumberFormat format, BuildContext context, WidgetRef ref, GymModel? gym) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('SỐ DƯ KHẢ DỤNG', style: TextStyle(letterSpacing: 2, fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(
            format.format(available),
            style: AppTextStyles.displayLarge.copyWith(color: AppColors.accentCyan),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (available < 50000 || gym == null) ? null : () => _showWithdrawDialog(context, ref, available, gym),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('RÚT TIỀN VỀ TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (available < 50000)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tối thiểu 50.000đ để rút tiền',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double total, double paid, double pending, NumberFormat format) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Tổng tích lũy', format.format(total), Icons.account_balance_wallet),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatItem('Chờ duyệt (Pending)', format.format(pending), Icons.hourglass_empty),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatItem('Đã rút', format.format(paid), Icons.outbox),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref, double maxAmount, GymModel gym) {
    final amountController = TextEditingController(text: maxAmount.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yêu cầu rút tiền', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.lg),
            
            _buildInfoCard('Ngân hàng', gym.bankName, Icons.account_balance),
            const SizedBox(height: 8),
            _buildInfoCard('Số tài khoản', gym.bankCardNumber, Icons.numbers),
            const SizedBox(height: 8),
            _buildInfoCard('Chủ tài khoản', gym.bankAccountName, Icons.person),
            
            const SizedBox(height: 24),
            _buildTextField(amountController, 'Số tiền rút (Tối thiểu 50k)', Icons.attach_money, isNumber: true),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount < 50000 || amount > maxAmount) return;
                  
                  final user = ref.read(authProvider).user;
                  if (user == null) return;

                  try {
                    await ref.read(partnerEarningsRepositoryProvider).requestWithdrawal(
                      user.uid,
                      gymId,
                      amount,
                      {
                        'bank': gym.bankName,
                        'account': gym.bankCardNumber,
                        'name': gym.bankAccountName,
                      },
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(paidWithdrawalsTotalProvider(gymId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gửi yêu cầu thành công!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('GỬI YÊU CẦU', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
