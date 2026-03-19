import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/withdrawal_model.dart';
import '../../models/gym_model.dart';

class PartnerEarningsRepository {
  final FirebaseFirestore _firestore;

  PartnerEarningsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate detailed earnings for a specific gym
  Future<Map<String, double>> calculateEarnings(String gymId) async {
    try {
      final logs = await _firestore
          .collection('revenue_logs')
          .where('gymId', isEqualTo: gymId)
          .get();

      double totalRevenue = 0.0;
      double availableRevenue = 0.0;
      final now = DateTime.now();

      // Collect all card IDs to fetch them in bulk
      final cardIds = logs.docs
          .map((doc) => doc.data()['cardId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      // Fetch cards in batches of 30 (Firestore limit for whereIn)
      Map<String, DateTime> cardPurchaseDates = {};
      for (int i = 0; i < cardIds.length; i += 30) {
        final batch = cardIds.sublist(i, i + 30 > cardIds.length ? cardIds.length : i + 30);
        final cardSnaps = await _firestore
            .collection('cards')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (var doc in cardSnaps.docs) {
          final purchasedAtTs = doc.data()['purchasedAt'] as Timestamp?;
          if (purchasedAtTs != null) {
            cardPurchaseDates[doc.id] = purchasedAtTs.toDate();
          }
        }
      }

      for (var doc in logs.docs) {
        final data = doc.data();
        final amount = (data['partnerEarned'] ?? 0.0).toDouble();
        final cardId = data['cardId'] as String?;

        totalRevenue += amount;

        if (cardId != null && cardPurchaseDates.containsKey(cardId)) {
          final purchasedAt = cardPurchaseDates[cardId]!;
          final unlockDate = purchasedAt.add(const Duration(days: 30));
          if (now.isAfter(unlockDate) || now.isAtSameMomentAs(unlockDate)) {
            availableRevenue += amount;
          }
        }
      }

      // Get withdrawal stats
      final withdrawals = await _firestore
          .collection('withdrawals')
          .where('gymId', isEqualTo: gymId)
          .get();

      double paid = 0.0;
      double pending = 0.0;

      for (var doc in withdrawals.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0.0).toDouble();
        final status = data['status'] as String?;

        if (status == 'paid') {
          paid += amount;
        } else if (status == 'pending') {
          pending += amount;
        }
      }

      return {
        'total': totalRevenue,
        'availableRevenue': availableRevenue,
        'paid': paid,
        'pending': pending,
        'availableToWithdraw': (availableRevenue - paid - pending).clamp(0.0, double.infinity),
      };
    } catch (e) {
      print('Error calculating earnings for gym $gymId: $e');
      return {
        'total': 0.0,
        'availableRevenue': 0.0,
        'paid': 0.0,
        'pending': 0.0,
        'availableToWithdraw': 0.0,
      };
    }
  }

  Future<double> getPaidWithdrawalsTotal(String gymId) async {
    final snapshots = await _firestore
        .collection('withdrawals')
        .where('gymId', isEqualTo: gymId)
        .where('status', isEqualTo: 'paid')
        .get();

    double total = 0.0;
    for (var doc in snapshots.docs) {
      total += (doc.data()['amount'] ?? 0.0).toDouble();
    }
    return total;
  }

  Future<void> requestWithdrawal(
    String partnerUid,
    String gymId,
    double amount,
    Map<String, dynamic> bankInfo,
  ) async {
    final docRef = _firestore.collection('withdrawals').doc();
    final withdrawal = WithdrawalModel(
      id: docRef.id,
      partnerUid: partnerUid,
      gymId: gymId,
      amount: amount,
      status: 'pending',
      timestamp: DateTime.now(),
      bankInfo: bankInfo,
    );
    await docRef.set(withdrawal.toMap());
  }

  /// Get partner withdrawals with pagination
  Stream<List<WithdrawalModel>> getPartnerWithdrawals(String gymId, {int limit = 5}) {
    return _firestore
        .collection('withdrawals')
        .where('gymId', isEqualTo: gymId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snaps) => snaps.docs
              .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Admin side
  Stream<List<WithdrawalModel>> getPendingWithdrawals() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snaps) => snaps.docs
              .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<WithdrawalModel>> getHistoryWithdrawals() {
    return _firestore
        .collection('withdrawals')
        .where('status', whereIn: ['paid', 'rejected'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snaps) => snaps.docs
              .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateWithdrawalStatus(
    String id,
    String status, {
    String? adminNote,
  }) async {
    await _firestore.collection('withdrawals').doc(id).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
      'adminNote': adminNote,
    });
  }

  /// Get detailed earnings logs for a gym with pagination
  Stream<List<Map<String, dynamic>>> getEarningsLogs(String gymId, {int limit = 5}) {
    return _firestore
        .collection('revenue_logs')
        .where('gymId', isEqualTo: gymId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'earnedAmount': data['partnerEarned'],
              'userName': 'Hội viên Vpass', 
            };
          }).toList();
        });
  }

  Future<GymModel?> getGym(String gymId) async {
    final doc = await _firestore.collection('gyms').doc(gymId).get();
    if (!doc.exists) return null;
    return GymModel.fromMap(doc.id, doc.data()!);
  }
}
