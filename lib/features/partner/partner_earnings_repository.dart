import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/withdrawal_model.dart';
import '../../models/gym_model.dart';

class PartnerEarningsRepository {
  final FirebaseFirestore _firestore;

  PartnerEarningsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calculate earnings (Total and Available/Unlocked) for a specific gym
  Future<Map<String, double>> calculateEarnings(String gymId) async {
    final logs = await _firestore
        .collection('revenue_logs')
        .where('gymId', isEqualTo: gymId)
        .get();

    double total = 0.0;
    double available = 0.0;
    final now = DateTime.now();

    for (var doc in logs.docs) {
      final data = doc.data();
      final amount = (data['partnerEarned'] ?? 0.0).toDouble();
      final cardId = data['cardId'] as String?;

      total += amount;

      // Check unlock status by fetching the associated card
      if (cardId != null) {
        final cardDoc = await _firestore.collection('cards').doc(cardId).get();
        if (cardDoc.exists) {
          final purchasedAtTs = cardDoc.data()?['purchasedAt'] as Timestamp?;
          if (purchasedAtTs != null) {
            final purchasedAt = purchasedAtTs.toDate();
            // Business Rule: Revenue is locked for 30 days from the card's purchase date.
            final unlockDate = purchasedAt.add(const Duration(days: 30));

            // Only add to 'available' if 30 days have fully passed.
            if (now.isAfter(unlockDate) || now.isAtSameMomentAs(unlockDate)) {
              available += amount;
            }
            // NOTE: If this log is a 'refund_reversal' (negative amount), it was issued for an Active card.
            // Active cards are strictly < 30 days old. Therefore, now < unlockDate, meaning 'available'
            // is NOT modified by the negative log. It only reduces 'total', which perfectly means
            // the refund strictly subtracts from the 'Pending' balance without touching 'Available'.
          }
        }
      }
    }

    return {'total': total, 'available': available};
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

  Stream<List<WithdrawalModel>> getPartnerWithdrawals(String gymId) {
    return _firestore
        .collection('withdrawals')
        .where('gymId', isEqualTo: gymId)
        .orderBy('timestamp', descending: true)
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

  Future<void> updateWithdrawalStatus(
    String id,
    String status, {
    String? adminNote,
  }) async {
    await _firestore.collection('withdrawals').doc(id).update({
      'status': status,
      'processedAt': FieldValue.serverTimestamp(),
      'adminNote': ?adminNote,
    });
  }

  /// Get detailed earnings logs for a gym (from purchase logs)
  Stream<List<Map<String, dynamic>>> getEarningsLogs(String gymId) {
    return _firestore
        .collection('revenue_logs')
        .where('gymId', isEqualTo: gymId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'earnedAmount': data['partnerEarned'],
              'userName':
                  'Hội viên Vpass', // Hide buyer name for privacy OR fetch if needed
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
