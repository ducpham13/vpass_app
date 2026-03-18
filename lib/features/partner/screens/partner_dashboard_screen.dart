import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'partner_earnings_screen.dart';

class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(partnerGymsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PARTNER DASHBOARD'),
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
                    name: user?.name ?? 'Partner',
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
                  Text('No gyms found. Create your first one!', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GymFormScreen()),
                    ),
                    child: const Text('CREATE GYM'),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gym.name.toUpperCase(),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontSize: 20,
                                    letterSpacing: 1.5,
                                    color: isInactive ? AppColors.textMuted : AppColors.accentCyan,
                                  ),
                                ),
                                Text(
                                  gym.address,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            onSelected: (value) {
                              if (value == 'contract') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym, isReadOnly: true)),
                                );
                              } else if (value == 'earnings') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartnerEarningsScreen(
                                      gymId: gym.id,
                                      gymName: gym.name,
                                    ),
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'contract',
                                child: Text('Thông tin hợp đồng'),
                              ),
                              const PopupMenuItem(
                                value: 'earnings',
                                child: Text('Xem doanh thu'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
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
                          gym.status.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isInactive 
                                ? AppColors.textMuted 
                                : (isPending ? AppColors.warning : AppColors.success),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Primary Scan Button
                      if (!isPending)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: isInactive ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ScannerScreen(gymId: gym.id)),
                              );
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 28),
                            label: const Text('QUÉT QR CHECK-IN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInactive ? Colors.grey : AppColors.accentBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Footer with Daily Ops Edit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (gym.status == 'rejected' && gym.rejectionReason != null)
                             Expanded(
                               child: Text(
                                 'Lý do từ chối: ${gym.rejectionReason}',
                                 style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                               ),
                             ),
                          
                          IconButton(
                            onPressed: isInactive ? null : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GymFormScreen(gym: gym, editOpsOnly: true)),
                            ),
                            icon: const Icon(Icons.edit_note, color: AppColors.accentCyan),
                            tooltip: 'Chỉnh sửa vận hành',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('L?i: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GymFormScreen()),
        ),
        label: const Text('New Gym Request'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.accentCyan,
      ),
    );
  }
}
