import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'deposit_repository.dart';
import '../../models/deposit_request_model.dart';
import '../auth/auth_provider.dart';

final depositRepositoryProvider = Provider((ref) => DepositRepository());

final userDepositRequestsProvider = StreamProvider<List<DepositRequestModel>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null) return Stream.value([]);
  return ref.read(depositRepositoryProvider).getUserDepositRequests(user.uid);
});

final pendingDepositRequestsProvider = StreamProvider<List<DepositRequestModel>>((ref) {
  return ref.read(depositRepositoryProvider).getPendingDepositRequests();
});
