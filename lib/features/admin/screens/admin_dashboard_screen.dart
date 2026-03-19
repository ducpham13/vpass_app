import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../admin_provider.dart';
import '../admin_user_provider.dart';
import 'admin_deposit_requests_screen.dart';
import 'gym_management_screen.dart';
import 'user_management_screen.dart';
import 'total_revenue_screen.dart';
import 'platform_profit_screen.dart';
import 'admin_settlement_screen.dart';
import '../../auth/auth_provider.dart';
import '../../auth/deposit_provider.dart';
import '../../cards/gym_provider.dart';
import '../../auth/screens/profile_screen.dart';
import '../../../shared/widgets/user_avatar.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedDate = ref.watch(selectedMonthProvider);

    final pendingGymsCount = ref.watch(allGymsProvider).when(
          data: (gyms) => gyms.where((g) => g.status == 'pending').length,
          loading: () => 0,
          error: (_, __) => 0,
        );
    final pendingDepositsCount = ref.watch(pendingDepositRequestsProvider).when(
          data: (requests) => requests.length,
          loading: () => 0,
          error: (_, __) => 0,
        );

    String formatValue(double value) {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(1)}K';
      }
      return value.toStringAsFixed(0);
    }

    return statsAsync.when(
      data: (stats) {
        String formattedRevenue = formatValue(stats.mtdRevenue.toDouble());
        String formattedProfit = formatValue(stats.platformProfit.toDouble());

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 70,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tháng ${selectedDate.month} / ${selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: UserAvatar(
                    name: user?.name ?? 'Admin',
                    radius: 18,
                    gradientColors: user?.role == 'admin' ? [AppColors.danger, const Color(0xFFEF4444)] : null,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildPendingCard(
                      emoji: '💳',
                      count: pendingDepositsCount.toString(),
                      label: 'DEPOSIT CHỜ\nDUYỆT',
                      dotColor: AppColors.warning,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDepositRequestsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPendingCard(
                      emoji: '🏋️',
                      count: pendingGymsCount.toString(),
                      label: 'GYM CHỜ\nDUYỆT',
                      dotColor: AppColors.accentBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GymManagementScreen(initialStatus: 'pending')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMonthSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(
                      title: 'TỔNG DOANH THU',
                      value: formattedRevenue,
                      valueColor: AppColors.accentBlue,
                      showArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TotalRevenueScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      title: 'LỢI NHUẬN PLATFORM',
                      value: formattedProfit,
                      valueColor: AppColors.success,
                      showArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlatformProfitScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      title: 'TỔNG USER',
                      value: stats.totalUsers.toString(),
                      valueColor: AppColors.accentPurple,
                      showArrow: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      title: 'THẺ ACTIVE',
                      value: stats.activeCards.toString(),
                      valueColor: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'TRUY CẬP NHANH',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildQuickAccessButton(
                      emoji: '💳',
                      label: 'Duyệt nạp tiền',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDepositRequestsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAccessButton(
                      emoji: '🏋️',
                      label: 'Duyệt gym',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GymManagementScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildQuickAccessButton(
                      emoji: '💰',
                      label: 'Settlement',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminSettlementScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Lỗi tải Dashboard: $e\nVui lòng SEED lại dữ liệu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final selectedDate = ref.watch(selectedMonthProvider);
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
            onTap: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month - 1);
            },
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
            'Tháng ${selectedDate.month} / ${selectedDate.year}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          GestureDetector(
            onTap: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month + 1);
            },
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

  Widget _buildPendingCard({
    required String emoji,
    required String count,
    required String label,
    required Color dotColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  if (showArrow) const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valueColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
