import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../checkin_provider.dart';

class CheckinHistoryScreen extends ConsumerWidget {
  final String gymId;
  const CheckinHistoryScreen({super.key, required this.gymId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(checkinHistoryProvider(gymId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử quét mã'),
      ),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text("Chưa có lượt check-in nào"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final timestamp = (log['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.accentBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['userName'] ?? "Member ${log['userId'].toString().substring(0, 5)}...",
                            style: AppTextStyles.bodyLarge,
                          ),
                          Text(
                            log['cardType']?.toString().toUpperCase() ?? "UNKNOWN",
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentCyan),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm\ndd/MM').format(timestamp),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }
}
