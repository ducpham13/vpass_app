import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../models/gym_model.dart';
import '../widgets/gym_card.dart';
import '../../../models/card_model.dart';
import 'card_detail_sheet.dart';
import '../card_provider.dart';
import '../gym_provider.dart';
import '../../auth/screens/wallet_screen.dart';
import '../../checkin/screens/training_history_screen.dart';
import 'store_screen.dart';
import '../../auth/auth_provider.dart';
import '../../auth/screens/profile_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/shimmer_loading.dart';
import '../../../shared/glass_container.dart';
import '../widgets/vip_membership_card.dart';
import 'vip_gym_selection_screen.dart';

class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showCardDetail(CardModel card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardDetailSheet(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(cardProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('THẺ CỦA TÔI'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrainingHistoryScreen()),
            ),
            color: AppColors.textMuted,
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            color: AppColors.accentBlue,
          ),
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
                    name: user?.name ?? 'User',
                    radius: 16,
                  );
                },
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentBlue,
          tabs: const [
            Tab(text: 'HOẠT ĐỘNG'),
            Tab(text: 'ĐÃ HẾT HẠN'),
          ],
        ),
      ),
      body: cardAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text("Bạn chưa có thẻ nào"));
          }

          final activeCards = cards.where((c) => c.isActive).toList()
            ..sort((a, b) => b.endDate.compareTo(a.endDate));
          final inactiveCards = cards.where((c) => c.isExpired).toList()
            ..sort((a, b) {
              final aTime = a.inactivatedAt ?? a.endDate;
              final bTime = b.inactivatedAt ?? b.endDate;
              return bTime.compareTo(aTime);
            });
          
          final gymsAsync = ref.watch(gymsProvider);

          return TabBarView(
            controller: _tabController,
            children: [
              // Active Tab
              _buildActiveTab(activeCards, gymsAsync),
              // Inactive Tab
              _buildCardList(inactiveCards, gymsAsync, isInactive: true),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerLoading(
              isLoading: true,
              child: GlassContainer(
                borderRadius: 24.0,
                child: Container(height: 180),
              ),
            ),
          ),
        ),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StoreScreen()),
        ),
        label: const Text('Mua Thẻ Mới'),
        icon: const Icon(Icons.shopping_bag_outlined),
        backgroundColor: AppColors.accentBlue,
      ),
    );
  }

  Widget _buildActiveTab(List<CardModel> activeCards, AsyncValue<List<GymModel>> gymsAsync) {
    if (activeCards.isEmpty) return const Center(child: Text('Danh sách trống'));

    final membershipCard = activeCards.firstWhereOrNull((c) => c.isMembership && c.gymId == null);

    if (membershipCard != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            VipMembershipCard(
              card: membershipCard,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VipGymSelectionScreen(card: membershipCard),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'NHẤN VÀO THẺ ĐỂ CHỌN PHÒNG TẬP',
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white24, letterSpacing: 1),
            ),
          ],
        ),
      );
    }

    return _buildCardList(activeCards, gymsAsync);
  }

  Widget _buildCardList(List<CardModel> cards, AsyncValue<List<GymModel>> gymsAsync, {bool isInactive = false}) {
    if (cards.isEmpty) return const Center(child: Text('Danh sách trống'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        
        final daysLeft = card.endDate.difference(DateTime.now()).inDays;
        String badgeText = daysLeft < 0 ? 'Hết hạn' : 'Còn $daysLeft ngày';
        
        if (card.status == 'expired' || card.status == 'superseded') {
          if (card.expiryReason == 'Upgraded to Global Membership') {
            badgeText = 'Đã nâng cấp VIP';
          } else if (card.expiryReason == 'Cancelled by User') {
            badgeText = 'Đã hủy';
          } else {
            badgeText = 'Hết hạn';
          }
        }

        // Handle VIP cards in Inactive list
        if (card.isMembership && card.gymId == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Opacity(
              opacity: isInactive ? 0.6 : 1.0,
              child: VipMembershipCard(
                card: card,
                statusBadge: isInactive ? badgeText : null,
                onTap: () => _showCardDetail(card),
              ),
            ),
          );
        }

        final gym = gymsAsync.whenOrNull(data: (gyms) => gyms.firstWhereOrNull((g) => g.id == card.gymId));

        final displayGym = gym ?? GymModel(
          id: card.gymId ?? '',
          name: 'Thẻ Tập Gym',
          address: 'Chi tiết Thẻ Tập',
          city: '',
          description: '',
          imageUrl: '',
          pricePerMonth: card.priceSnapshot,
          ownerUid: '',
          ownerName: '',
          partnerEmail: '',
          bankName: '',
          bankCardNumber: '',
          bankAccountName: '',
          feeRate: 0,
          status: 'active',
          openTime: '06:00',
          closeTime: '22:00',
          crowdLevel: 'average',
          isClosedOverride: false,
        );

        return Opacity(
          opacity: isInactive ? 0.6 : 1.0,
          child: GymCard(
            gym: displayGym,
            showOperationalInfo: true,
            customBadgeText: badgeText,
            useSolidColor: true,
            onTap: () => _showCardDetail(card),
          ),
        );
      },
    );
  }
}
