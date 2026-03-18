import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../cards/card_provider.dart';
import '../cards/gym_provider.dart';
import '../../models/card_model.dart';
import '../../models/user_model.dart';

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(authRepositoryProvider).getUsersStream();
});

final allCardsStreamProvider = StreamProvider<List<CardModel>>((ref) {
  return ref.read(cardRepositoryProvider).getAllCardsStream();
});

class AdminStats {
  final int totalUsers;
  final int activeCards;
  final double mtdRevenue;
  final double platformProfit;
  final double regularCardProfit;
  final double vipFeeProfit;
  final double unusedVipQuotaProfit;
  final double totalRegularRevenue;
  final double totalVipRevenue;
  final double regularGymPayout;
  final double vipGymPayout;

  AdminStats({
    this.totalUsers = 0,
    this.activeCards = 0,
    this.mtdRevenue = 0,
    this.platformProfit = 0,
    this.regularCardProfit = 0,
    this.vipFeeProfit = 0,
    this.unusedVipQuotaProfit = 0,
    this.totalRegularRevenue = 0,
    this.totalVipRevenue = 0,
    this.regularGymPayout = 0,
    this.vipGymPayout = 0,
  });
}

final adminStatsProvider = Provider<AsyncValue<AdminStats>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final cardsAsync = ref.watch(allCardsStreamProvider);
  final gymsAsync = ref.watch(allGymsProvider);

  return usersAsync.when(
    data: (users) => cardsAsync.when(
      data: (cards) => gymsAsync.when(
        data: (gyms) {
          final activeCards = cards.where((c) => c.isActive).toList();
          double totalRevenue = 0.0;
          double platformProfit = 0.0;
          double regularCardProfit = 0.0;
          double vipFeeProfit = 0.0;
          double unusedVipQuotaProfit = 0.0;
          double totalRegularRevenue = 0.0;
          double totalVipRevenue = 0.0;
          double regularGymPayout = 0.0;
          double vipGymPayout = 0.0;

          for (var card in cards) {
            totalRevenue += card.priceSnapshot;
            
            if (card.gymId != null) {
              // Regular Card: Platform gets 10%
              regularCardProfit += card.priceSnapshot * 0.1;
              platformProfit += card.priceSnapshot * 0.1;
              totalRegularRevenue += card.priceSnapshot;
              regularGymPayout += card.priceSnapshot * 0.9;
            } else {
              // VIP Card: Platform gets 5% upfront
              vipFeeProfit += card.priceSnapshot * 0.05;
              platformProfit += card.priceSnapshot * 0.05;
              totalVipRevenue += card.priceSnapshot;
              vipGymPayout += card.usedValue; // Gyms get exactly what is used
              
              // If expired, platform keeps the unused quota
              if (card.isExpired || card.status == 'inactive') {
                final unusedQuota = (card.priceSnapshot * 0.95) - card.usedValue;
                if (unusedQuota > 0) {
                  unusedVipQuotaProfit += unusedQuota;
                  platformProfit += unusedQuota;
                }
              }
            }
          }

          return AsyncValue.data(AdminStats(
            totalUsers: users.length,
            activeCards: activeCards.length,
            mtdRevenue: totalRevenue,
            platformProfit: platformProfit,
            regularCardProfit: regularCardProfit,
            vipFeeProfit: vipFeeProfit,
            unusedVipQuotaProfit: unusedVipQuotaProfit,
            totalRegularRevenue: totalRegularRevenue,
            totalVipRevenue: totalVipRevenue,
            regularGymPayout: regularGymPayout,
            vipGymPayout: vipGymPayout,
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});
