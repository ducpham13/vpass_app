import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/glass_container.dart';
import '../../auth/auth_provider.dart';
import '../../cards/gym_provider.dart';
import '../partner_earnings_provider.dart';
import '../../../models/gym_model.dart';

class PartnerEarningsScreen extends ConsumerStatefulWidget {
  final String gymId;
  final String gymName;

  const PartnerEarningsScreen({
    super.key,
    required this.gymId,
    required this.gymName,
  });

  @override
  ConsumerState<PartnerEarningsScreen> createState() => _PartnerEarningsScreenState();
}

class _PartnerEarningsScreenState extends ConsumerState<PartnerEarningsScreen> {
  int _logsLimit = 5;
  int _withdrawalsLimit = 5;

  @override
  Widget build(BuildContext context) {
    final earningsAsync = ref.watch(earningsProvider(widget.gymId));
    final logsAsync = ref.watch(earningsLogsProvider((widget.gymId, _logsLimit)));
    final gymAsync = ref.watch(gymDetailProvider(widget.gymId));
    final withdrawalsAsync = ref.watch(partnerWithdrawalsProvider((widget.gymId, _withdrawalsLimit)));
    
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final gym = gymAsync.value;

    return Scaffold(
      appBar: AppBar(title: Text('THU NHẬP - ${widget.gymName}')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(earningsProvider(widget.gymId));
          ref.invalidate(earningsLogsProvider((widget.gymId, _logsLimit)));
          ref.invalidate(partnerWithdrawalsProvider((widget.gymId, _withdrawalsLimit)));
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            // Header Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: earningsAsync.when(
                  data: (stats) {
                    final totalEarned = stats['total'] ?? 0.0;
                    final availableRevenue = stats['availableRevenue'] ?? 0.0;
                    final locked = (totalEarned - availableRevenue).clamp(0.0, double.infinity);
                    final paid = stats['paid'] ?? 0.0;
                    final pendingWithdrawal = stats['pending'] ?? 0.0;
                    final availableToWithdraw = stats['availableToWithdraw'] ?? 0.0;
                    
                    return Column(
                      children: [
                        _buildBalanceCard(
                          availableToWithdraw,
                          currencyFormat,
                          context,
                          ref,
                          gym,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildStatsRow(
                          totalEarned,
                          paid,
                          locked,
                          pendingWithdrawal,
                          currencyFormat,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger),
                        const SizedBox(height: 8),
                        Text('Lỗi tải doanh thu: $err', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                        TextButton(
                          onPressed: () => ref.invalidate(earningsProvider(widget.gymId)),
                          child: const Text('THỬ LẠI'),
                        )
                      ],
                    ),
                  ),
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
                    Text(
                      'Lịch sử doanh thu',
                      style: AppTextStyles.displaySmall,
                    ),
                    const Icon(Icons.history, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            // Logs List
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Chưa có lịch sử giao dịch',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == logs.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(() => _logsLimit += 5),
                            child: const Text('XEM THÊM DOANH THU'),
                          ),
                        ),
                      );
                    }
                    
                    final log = logs[index];
                    final Timestamp? ts = log['timestamp'] as Timestamp?;
                    final time = ts?.toDate() ?? DateTime.now();
                    final now = DateTime.now();
                    final timeStr = now.year == time.year
                        ? DateFormat('HH:mm - dd/MM').format(time)
                        : DateFormat('HH:mm - dd/MM/yyyy').format(time);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  (log['type'] == 'checkin_vip'
                                          ? AppColors.accentBlue
                                          : AppColors.accentCyan)
                                      .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              log['type'] == 'checkin_vip'
                                  ? Icons.login
                                  : Icons.add_card,
                              color: log['type'] == 'checkin_vip'
                                  ? AppColors.accentBlue
                                  : AppColors.accentCyan,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['type'] == 'checkin_vip'
                                      ? 'Check-in VIP'
                                      : 'Bán thẻ mới',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  log['userName'] ?? 'Hội viên Vpass',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+${currencyFormat.format(log['earnedAmount'])}',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }, childCount: logs.length + (logs.length >= _logsLimit ? 1 : 0)),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Lỗi: $err'))),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Withdrawal History Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lịch sử rút tiền', style: AppTextStyles.displaySmall),
                    const Icon(
                      Icons.account_balance,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Withdrawal History List
            withdrawalsAsync.when(
              data: (withdrawals) {
                if (withdrawals.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Chưa có yêu cầu rút tiền nào',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == withdrawals.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(() => _withdrawalsLimit += 5),
                            child: const Text('XEM THÊM LỊCH SỬ RÚT TIỀN'),
                          ),
                        ),
                      );
                    }

                    final withdrawal = withdrawals[index];
                    final time = withdrawal.timestamp;
                    final now = DateTime.now();
                    final timeStr = now.year == time.year
                        ? DateFormat('HH:mm - dd/MM').format(time)
                        : DateFormat('HH:mm - dd/MM/yyyy').format(time);

                    Color statusColor;
                    String statusText;
                    switch (withdrawal.status) {
                      case 'paid':
                        statusColor = AppColors.success;
                        statusText = 'Đã thanh toán';
                        break;
                      case 'rejected':
                        statusColor = AppColors.danger;
                        statusText = 'Bị từ chối';
                        break;
                      default:
                        statusColor = AppColors.warning;
                        statusText = 'Đang chờ duyệt';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currencyFormat.format(withdrawal.amount),
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: statusColor,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                timeStr,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (withdrawal.adminNote != null &&
                                  withdrawal.adminNote!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Ghi chú: ${withdrawal.adminNote}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.warning,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }, childCount: withdrawals.length + (withdrawals.length >= _withdrawalsLimit ? 1 : 0)),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Lỗi: $err'))),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    double withdrawable,
    NumberFormat format,
    BuildContext context,
    WidgetRef ref,
    GymModel? gym,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'SỐ TIỀN CÓ THỂ RÚT',
            style: TextStyle(
              letterSpacing: 2,
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            format.format(withdrawable),
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (withdrawable < 50000 || gym == null)
                  ? null
                  : () => _showWithdrawDialog(context, ref, withdrawable, gym),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'RÚT TIỀN VỀ TÀI KHOẢN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (withdrawable < 50000)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tối thiểu 50.000đ để rút tiền',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    double totalEarned,
    double paid,
    double locked,
    double pendingWithdrawal,
    NumberFormat format,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Tổng thu nhập',
                format.format(totalEarned),
                Icons.account_balance_wallet,
                subtitle: 'Toàn bộ tiền kiếm được từ trước tới nay',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatItem(
                'Đã rút',
                format.format(paid),
                Icons.outbox,
                subtitle: 'Tiền đã được chuyển về ngân hàng',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Đang khóa (30 ngày)',
                format.format(locked),
                Icons.lock_outline,
                subtitle: 'Doanh thu mới chưa đủ 30 ngày để rút',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatItem(
                'Đang chờ duyệt',
                format.format(pendingWithdrawal),
                Icons.hourglass_empty,
                subtitle: 'Yêu cầu rút tiền đang chờ Admin xử lý',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.2),
              ),
            ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    WidgetRef ref,
    double maxAmount,
    GymModel gym,
  ) {
    final amountController = TextEditingController(
      text: maxAmount.toInt().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
            _buildTextField(
              amountController,
              'Số tiền rút (Tối thiểu 50k)',
              Icons.attach_money,
              isNumber: true,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amountText = amountController.text;
                  final amount = double.tryParse(amountText) ?? 0;
                  if (amount < 50000 || amount > maxAmount) return;

                  final user = ref.read(authProvider).user;
                  if (user == null) return;

                  try {
                    await ref
                        .read(partnerEarningsRepositoryProvider)
                        .requestWithdrawal(user.uid, widget.gymId, amount, {
                          'bank': gym.bankName,
                          'account': gym.bankCardNumber,
                          'name': gym.bankAccountName,
                        });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ref.invalidate(earningsProvider(widget.gymId));
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GỬI YÊU CẦU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
