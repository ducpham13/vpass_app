import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../models/card_model.dart';

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList());
});

class UserSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

final userSearchQueryProvider = NotifierProvider<UserSearchQuery, String>(UserSearchQuery.new);

final filteredUsersProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(allUsersProvider);
  final query = ref.watch(userSearchQueryProvider).toLowerCase();

  return usersAsync.whenData((users) {
    if (query.isEmpty) return users;
    return users.where((u) => 
      u.name.toLowerCase().contains(query) || 
      u.email.toLowerCase().contains(query)
    ).toList();
  });
});

final userCardsProvider = StreamProvider.family<List<CardModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('cards')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) => snap.docs.map((doc) => CardModel.fromMap(doc.id, doc.data())).toList());
});

final userTransactionsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final tsA = a['timestamp'] as Timestamp?;
          final tsB = b['timestamp'] as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA);
        });
        return list;
      });
});

final userCheckinsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('checkins')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final tsA = a['timestamp'] as Timestamp?;
          final tsB = b['timestamp'] as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA);
        });
        return list;
      });
});

final partnerRevenueProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, partnerUid) {
  return FirebaseFirestore.instance
      .collection('revenue_logs')
      .where('partnerUid', isEqualTo: partnerUid)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((doc) => doc.data()).toList();
        list.sort((a, b) {
          final tsA = a['timestamp'] as Timestamp?;
          final tsB = b['timestamp'] as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA);
        });
        return list;
      });
});

final adminUserActionsProvider = Provider((ref) => AdminUserActions());

class AdminUserActions {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleUserLock(String userId, bool isLocked) async {
    await _firestore.collection('users').doc(userId).update({
      'isLocked': isLocked,
    });
  }
}
