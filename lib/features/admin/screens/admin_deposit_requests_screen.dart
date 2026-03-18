import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/deposit_provider.dart';

class AdminDepositRequestsScreen extends ConsumerWidget {
  const AdminDepositRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingDepositRequestsProvider);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('DUYỆT NẠP TIỀN'),
      ),
      body: pendingAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu nào đang chờ'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.userName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(req.timestamp),
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${fmt.format(req.amount)}đ',
                          style: AppTextStyles.displaySmall.copyWith(color: AppColors.accentCyan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: AppColors.accentBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Nội dung CK: ',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                          Text(
                            req.adminNote ?? 'N/A',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(context, ref, req.id),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                            child: const Text('TỪ CHỐI'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approve(context, ref, req),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('CHẤP NHẬN'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, dynamic req) async {
    try {
      await ref.read(depositRepositoryProvider).approveDeposit(req.id, req.userId, req.amount);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt nạp tiền thành công!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String requestId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Lý do từ chối'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY')),
          TextButton(
            onPressed: () async {
              await ref.read(depositRepositoryProvider).rejectDeposit(requestId, noteController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã từ chối yêu cầu')),
                );
              }
            },
            child: const Text('XÁC NHẬN', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
