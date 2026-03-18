import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../card_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/card_model.dart';
import '../../../models/gym_model.dart';
import '../gym_provider.dart';
import '../widgets/gym_card.dart';
import 'card_detail_sheet.dart';

class VipGymSelectionScreen extends ConsumerStatefulWidget {
  final CardModel card;

  const VipGymSelectionScreen({
    super.key,
    required this.card,
  });

  @override
  ConsumerState<VipGymSelectionScreen> createState() => _VipGymSelectionScreenState();
}

class _VipGymSelectionScreenState extends ConsumerState<VipGymSelectionScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(gymsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('CHỌN PHÒNG TẬP VIP'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _handleCancel(context, ref),
            child: const Text('HỦY THẺ', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên phòng, khu vực...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: AppColors.accentCyan),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Gym List
          Expanded(
            child: gymsAsync.when(
              data: (gyms) {
                final filteredGyms = gyms.where((g) {
                  return g.name.toLowerCase().contains(_searchQuery) ||
                      g.city.toLowerCase().contains(_searchQuery) ||
                      g.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredGyms.isEmpty) {
                  return const Center(
                    child: Text('Không tìm thấy phòng tập nào', style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: filteredGyms.length,
                  itemBuilder: (context, index) {
                    final gym = filteredGyms[index];
                    return _buildGymItem(context, gym);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Lỗi: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymItem(BuildContext context, GymModel gym) {
    // Calculate sessions
    int estimatedRemaining = 0;
    final limit = (widget.card.membershipPrice ?? 0) * 0.95;
    final remainingValue = limit - widget.card.usedValue;
    final sessionPrice = gym.pricePerMonth / 30;
    if (remainingValue > 0 && sessionPrice > 0) {
      estimatedRemaining = (remainingValue / sessionPrice).floor();
    }

    return GymCard(
      gym: gym,
      useSolidColor: true,
      customBadgeText: '~$estimatedRemaining buổi',
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CardDetailSheet(card: widget.card, initialGym: gym),
        );
      },
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Xác nhận hủy thẻ VIP'),
        content: const Text('Bạn có chắc chắn muốn hủy thẻ VIP Global này không? Sau khi hủy, bạn sẽ không thể tập tại bất kỳ phòng tập nào trong hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('KHÔNG')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('CÓ, HỦY THẺ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(cardRepositoryProvider).updateCardStatus(
        widget.card.id, 
        'expired',
        reason: 'Cancelled by User',
      );
      if (context.mounted) {
        Navigator.pop(context); // Back to cards screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy thẻ VIP thành công.'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
