import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

final historyDepositRequestsProvider = StreamProvider<List<DepositRequestModel>>((ref) {
  return ref.read(depositRepositoryProvider).getHistoryDepositRequests();
});

final depositSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredPendingDepositsProvider = Provider<AsyncValue<List<DepositRequestModel>>>((ref) {
  final query = ref.watch(depositSearchQueryProvider).toLowerCase();
  final requestsAsync = ref.watch(pendingDepositRequestsProvider);

  return requestsAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((req) {
      return req.userName.toLowerCase().contains(query) ||
          (req.adminNote?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});

final filteredHistoryDepositsProvider = Provider<AsyncValue<List<DepositRequestModel>>>((ref) {
  final query = ref.watch(depositSearchQueryProvider).toLowerCase();
  final requestsAsync = ref.watch(historyDepositRequestsProvider);

  return requestsAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((req) {
      return req.userName.toLowerCase().contains(query) ||
          (req.adminNote?.toLowerCase().contains(query) ?? false);
    }).toList();
  });
});
