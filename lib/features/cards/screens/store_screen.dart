import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../gym_provider.dart';
import 'gym_detail_screen.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../widgets/gym_card.dart';
import '../../../shared/shimmer_loading.dart';
import '../../auth/auth_provider.dart';
import '../card_provider.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(gymsProvider);
    final cardAsync = ref.watch(cardProvider);
    final isVipActive = cardAsync.asData?.value.any((c) => c.isMembership && c.gymId == null && c.isActive) ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('KHÁM PHÁ PHÒNG TẬP'),
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, địa chỉ...',
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: gymsAsync.when(
        data: (gyms) {
          final filteredGyms = gyms.where((gym) {
            final query = _searchQuery.toLowerCase();
            return gym.name.toLowerCase().contains(query) ||
                gym.address.toLowerCase().contains(query) ||
                gym.city.toLowerCase().contains(query);
          }).toList();

          if (filteredGyms.isEmpty) {
            return const Center(child: Text("Không tìm thấy phòng tập nào"));
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Global Membership Banner
              _buildGlobalMembershipBanner(context, ref, isVipActive),
              const SizedBox(height: AppSpacing.lg),
              
              Text('Phòng tập đối tác', style: AppTextStyles.labelLarge.copyWith(color: Colors.white38)),
              const SizedBox(height: AppSpacing.md),
              
              ...filteredGyms.map((gym) {
                final formattedPrice = '${NumberFormat("#,###").format(gym.pricePerMonth)}đ/th';
                return GymCard(
                  gym: gym,
                  useSolidColor: true,
                  showOperationalInfo: false,
                  customBadgeText: isVipActive ? 'BẠN ĐANG LÀ VIP' : formattedPrice,
                  onTap: isVipActive ? () {} : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GymDetailScreen(gym: gym)),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 6,
          itemBuilder: (context, index) => ShimmerLoading(
            isLoading: true,
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  Widget _buildGlobalMembershipBanner(BuildContext context, WidgetRef ref, bool isVipActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.stars, color: Colors.white, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PHỔ BIẾN NHẤT',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'THẺ VPASS GLOBAL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Text(
            'Tập luyện tại tất cả phòng tập đối tác',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '500,000đ / tháng',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: isVipActive ? null : () => _showGlobalPurchaseConfirm(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVipActive ? Colors.white24 : Colors.white,
                  foregroundColor: isVipActive ? Colors.white38 : const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  isVipActive ? 'BẠN ĐANG LÀ VIP' : 'MUA NGAY',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGlobalPurchaseConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B3A),
        title: const Text('Xác nhận mua thẻ Global', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Thẻ Global có giá 500,000đ và có hiệu lực 30 ngày trên toàn bộ hệ thống Vpass.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'LƯU Ý QUAN TRỌNG:',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Khi nâng cấp lên Global, TẤT CẢ các thẻ đang hoạt động khác của bạn sẽ bị KHÓA ngay lập tức và KHÔNG hoàn tiền. Bạn có chắc chắn muốn tiếp tục?',
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(authProvider).user;
              if (user == null) return;
              
              final success = await ref.read(gymRepositoryProvider).purchaseGlobalCard(user.uid);
              if (context.mounted) {
                if (success) {
                  await ref.read(authProvider.notifier).refreshUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mua thẻ Global thành công!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context); // Return to cards screen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số dư không đủ hoặc có lỗi xảy ra.'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }
}
