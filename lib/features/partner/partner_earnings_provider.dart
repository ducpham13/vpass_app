import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'partner_earnings_repository.dart';
import '../../models/withdrawal_model.dart';

final partnerEarningsRepositoryProvider = Provider((ref) => PartnerEarningsRepository());

final allRevenueLogsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, gymId) {
  return FirebaseFirestore.instance
      .collection('revenue_logs')
      .where('gymId', isEqualTo: gymId)
      .snapshots()
      .map((snaps) => snaps.docs.map((d) => d.data()).toList());
});

final allWithdrawalsProvider = StreamProvider.family<List<WithdrawalModel>, String>((ref, gymId) {
  return ref.watch(partnerEarningsRepositoryProvider).getAllWithdrawals(gymId);
});

final earningsProvider = Provider.family<AsyncValue<Map<String, double>>, String>((ref, gymId) {
  final logsAsync = ref.watch(allRevenueLogsProvider(gymId));
  final withdrawalsAsync = ref.watch(allWithdrawalsProvider(gymId));

  if (logsAsync.isLoading || withdrawalsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (logsAsync.hasError) return AsyncValue.error(logsAsync.error!, logsAsync.stackTrace!);
  if (withdrawalsAsync.hasError) return AsyncValue.error(withdrawalsAsync.error!, withdrawalsAsync.stackTrace!);

  final logs = logsAsync.value ?? [];
  final withdrawals = withdrawalsAsync.value ?? [];

  double totalRevenue = 0.0;
  double availableRevenue = 0.0;
  final now = DateTime.now();

  for (var data in logs) {
    final rawAmount = data['partnerEarned'];
    double amount = 0.0;
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount) ?? 0.0;
    }
    
    totalRevenue += amount;

    final dynamic tsRaw = data['timestamp'];
    if (tsRaw is Timestamp) {
      final logDate = tsRaw.toDate();
      final unlockDate = logDate.add(const Duration(days: 30));
      if (now.isAfter(unlockDate) || now.isAtSameMomentAs(unlockDate)) {
        availableRevenue += amount;
      }
    } else if (tsRaw == null) {
      // If no timestamp yet (optimistic update), assume locked
    }
  }

  double paid = 0.0;
  double pending = 0.0;

  for (var w in withdrawals) {
    if (w.status == 'paid') {
      paid += w.amount;
    } else if (w.status == 'pending') {
      pending += w.amount;
    }
  }

  return AsyncValue.data({
    'total': totalRevenue,
    'availableRevenue': availableRevenue,
    'paid': paid,
    'pending': pending,
    'availableToWithdraw': (availableRevenue - paid - pending).clamp(0.0, double.infinity),
  });
});

final revenueLogsUpdateProvider = StreamProvider.family<void, String>((ref, gymId) {
  return FirebaseFirestore.instance
      .collection('revenue_logs')
      .where('gymId', isEqualTo: gymId)
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
