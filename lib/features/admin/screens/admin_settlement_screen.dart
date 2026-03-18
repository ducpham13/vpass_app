import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/glass_container.dart';
import '../admin_user_provider.dart';
import '../../partner/partner_earnings_provider.dart';
import '../../../models/withdrawal_model.dart';

class AdminSettlementScreen extends ConsumerWidget {
  const AdminSettlementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingWithdrawalsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUẢN LÝ ĐỐI SOÁT'),
      ),
      body: pendingAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text('Không có yêu cầu rút tiền nào đang chờ xử lý.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _WithdrawalCard(request: request, currencyFormat: currencyFormat);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}

class _WithdrawalCard extends ConsumerWidget {
  final WithdrawalModel request;
  final NumberFormat currencyFormat;

  const _WithdrawalCard({required this.request, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(request.timestamp);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(request.amount),
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.accentCyan),
              ),
              Text(timeStr, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildInfoRow('Đối tác (UID)', request.partnerUid),
          _buildInfoRow('Ngân hàng', request.bankInfo['bank'] ?? 'N/A'),
          _buildInfoRow('Số tài khoản', request.bankInfo['account'] ?? 'N/A'),
          _buildInfoRow('Chủ tài khoản', request.bankInfo['name'] ?? 'N/A'),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showBreakdown(context, ref),
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('XEM LỊCH SỬ MUA THẺ (ĐỐI SOÁT)'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentCyan,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction(context, ref, 'rejected'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('TỪ CHỐI'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(context, ref, 'paid'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('ĐÃ THANH TOÁN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBreakdown(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('LỊCH SỬ MUA THẺ', style: AppTextStyles.labelLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ref.watch(partnerRevenueProvider(request.partnerUid)).when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu giao dịch'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final ts = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      return ListTile(
                        title: Text(log['gymName'] ?? 'Gym'),
                        subtitle: Text(DateFormat('HH:mm dd/MM/yyyy').format(ts)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${currencyFormat.format(log['partnerEarned'])}',
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Gốc: ${currencyFormat.format(log['buyPrice'])}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Lỗi: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'paid' ? 'Xác nhận thanh toán?' : 'Từ chối yêu cầu?'),
        content: Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ĐỒNG Ý')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(partnerEarningsRepositoryProvider).updateWithdrawalStatus(request.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: $status')),
        );
      }
    }
  }
}
