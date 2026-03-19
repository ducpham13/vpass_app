import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/glass_container.dart';
import '../../cards/gym_provider.dart';
import '../../admin/screens/gym_form_screen.dart';
import '../../checkin/screens/scanner_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../auth/auth_provider.dart';
import '../partner_earnings_provider.dart';
import 'partner_earnings_screen.dart';

class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(partnerGymsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QUẢN LÝ PHÒNG TẬP'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(authProvider).user;
                  
                  return UserAvatar(
                    name: user?.name ?? 'Đối tác',
                    radius: 16,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: gymsAsync.when(
        data: (gyms) {
          if (gyms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Chưa có phòng tập nào. Hãy tạo phòng tập đầu tiên!', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GymFormScreen()),
                    ),
                    child: const Text('TẠO PHÒNG TẬP'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index];
              final isPending = gym.status == 'pending';
              final isInactive = gym.status == 'inactive';
              
              return Opacity(
                opacity: isInactive ? 0.6 : 1.0,
                child: GlassContainer(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with 3-dot menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gym.name.toUpperCase(),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontSize: 18,
                                    letterSpacing: 1.2,
                                    color: isInactive ? AppColors.textMuted : AppColors.accentCyan,
                                  ),
                                ),
                                Text(
                                  gym.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action Icons Row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Wallet / Earnings
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.accentCyan, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartnerEarningsScreen(
                                      gymId: gym.id,
                                      gymName: gym.name,
                                    ),
                                  ),
                                ),
                                tooltip: 'Thu nhập',
                              ),
                              // Contract Details (formerly 3-dots)
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: const Icon(Icons.description_outlined, color: Colors.white70, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym, isReadOnly: true)),
                                ),
                                tooltip: 'Chi tiết hợp đồng',
                              ),
                              // Operational Notes
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(8),
                                icon: const Icon(Icons.edit_note, color: AppColors.accentCyan, size: 22),
                                onPressed: isInactive ? null : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym, editOpsOnly: true)),
                                ),
                                tooltip: 'Vận hành',
                              ),
                            ],
                          ),
                        ],
                      ),
                        
                        const SizedBox(height: 12),
                        
                        // Earnings Summary
                        Consumer(
                          builder: (context, ref, child) {
                            final earningsAsync = ref.watch(earningsProvider(gym.id));
                            return earningsAsync.when(
                              data: (stats) => Row(
                                children: [
                                  Text(
                                    'Thu nhập khả dụng: ',
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                                  ),
                                  Text(
                                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                                        .format(stats['availableToWithdraw'] ?? 0),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.accentCyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const SizedBox(height: 16),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isInactive 
                                ? AppColors.textMuted.withOpacity(0.1)
                                : (isPending 
                                    ? AppColors.warning.withOpacity(0.1) 
                                    : AppColors.success.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isInactive 
                                  ? AppColors.textMuted.withOpacity(0.3)
                                  : (isPending ? AppColors.warning : AppColors.success),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            gym.status == 'pending' ? 'ĐANG CHỜ DUYỆT' : (gym.status == 'active' ? 'ĐANG HOẠT ĐỘNG' : (gym.rejectionReason != null ? 'BỊ TỪ CHỐI' : 'NGỪNG HOẠT ĐỘNG')),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isInactive 
                                  ? AppColors.textMuted 
                                  : (isPending ? AppColors.warning : AppColors.success),
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),

                      if ((gym.status == 'rejected' || gym.status == 'inactive') && gym.rejectionReason != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 8, bottom: 16),
                           child: Text(
                             'Lý do từ chối: ${gym.rejectionReason}',
                             style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                           ),
                         ),
                      
                      const SizedBox(height: 16),
                      
                      // Primary Scan Button (Footer)
                      if (!isPending)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: isInactive ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ScannerScreen(gymId: gym.id)),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 24),
                            label: const Text('QUÉT QR CHECK-IN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInactive ? Colors.grey : AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GymFormScreen()),
        ),
        label: const Text('Đăng ký phòng tập mới'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accentCyan,
      ),
    );
  }
}
