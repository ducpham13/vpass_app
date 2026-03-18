import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'partner_earnings_repository.dart';
import '../../models/withdrawal_model.dart';

final partnerEarningsRepositoryProvider = Provider((ref) => PartnerEarningsRepository());

final earningsProvider = FutureProvider.family<Map<String, double>, String>((ref, gymId) {
  return ref.watch(partnerEarningsRepositoryProvider).calculateEarnings(gymId);
});

final paidWithdrawalsTotalProvider = FutureProvider.family<double, String>((ref, gymId) {
  return ref.watch(partnerEarningsRepositoryProvider).getPaidWithdrawalsTotal(gymId);
});

final partnerWithdrawalsProvider = StreamProvider.family<List<WithdrawalModel>, String>((ref, gymId) {
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getPartnerWithdrawals(gymId);
});

final pendingWithdrawalsProvider = StreamProvider<List<WithdrawalModel>>((ref) {
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getPendingWithdrawals();
});

final earningsLogsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, gymId) {
  final repo = ref.watch(partnerEarningsRepositoryProvider);
  return repo.getEarningsLogs(gymId);
});
