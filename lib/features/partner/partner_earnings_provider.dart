import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'partner_earnings_repository.dart';
import '../../models/withdrawal_model.dart';

final partnerEarningsRepositoryProvider = Provider((ref) => PartnerEarningsRepository());

final earningsProvider = FutureProvider.family<Map<String, double>, String>((ref, gymId) {
  // Watch withdrawal stream to trigger refresh when status changes (admin approval)
  ref.watch(partnerWithdrawalsProvider((gymId, 20)));
  
  // Watch revenue logs stream (latest entry only) to trigger refresh on new sales/check-ins
  ref.watch(revenueLogsUpdateProvider(gymId));

  return ref.watch(partnerEarningsRepositoryProvider).calculateEarnings(gymId);
});

final revenueLogsUpdateProvider = StreamProvider.family<void, String>((ref, gymId) {
  return FirebaseFirestore.instance
      .collection('revenue_logs')
      .where('gymId', isEqualTo: gymId)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .map((_) => null);
});

final paidWithdrawalsTotalProvider = FutureProvider.family<double, String>((ref, gymId) {
  return ref.watch(partnerEarningsRepositoryProvider).getPaidWithdrawalsTotal(gymId);
});

final partnerWithdrawalsProvider = StreamProvider.family<List<WithdrawalModel>, (String, int)>((ref, arg) {
  final gymId = arg.$1;
  final limit = arg.$2;
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getPartnerWithdrawals(gymId, limit: limit);
});

final pendingWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getPendingWithdrawals();
});

final historyWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getHistoryWithdrawals();
});

final settlementSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPendingWithdrawalsProvider = Provider<AsyncValue<List<WithdrawalModel>>>((ref) {
  final query = ref.watch(settlementSearchQueryProvider).toLowerCase();
  final requestsAsync = ref.watch(pendingWithdrawalsProvider);

  return requestsAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((req) {
      // Search by Gym ID, Partner UID, or Bank Name for now
      return req.gymId.toLowerCase().contains(query) ||
          req.partnerUid.toLowerCase().contains(query) ||
          (req.bankInfo['bank']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  });
});

final filteredHistoryWithdrawalsProvider = Provider<AsyncValue<List<WithdrawalModel>>>((ref) {
  final query = ref.watch(settlementSearchQueryProvider).toLowerCase();
  final requestsAsync = ref.watch(historyWithdrawalsProvider);

  return requestsAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((req) {
      return req.gymId.toLowerCase().contains(query) ||
          req.partnerUid.toLowerCase().contains(query) ||
          (req.bankInfo['bank']?.toString().toLowerCase().contains(query) ?? false);
    }).toList();
  });
});

final earningsLogsProvider = StreamProvider.family<List<Map<String, dynamic>>, (String, int)>((ref, arg) {
  final gymId = arg.$1;
  final limit = arg.$2;
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getEarningsLogs(gymId, limit: limit);
});
