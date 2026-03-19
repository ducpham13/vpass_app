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

      for (var doc in logs.docs) {
        final data = doc.data();
        final rawAmount = data['partnerEarned'];
        
        // Robust numeric conversion
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

  /// Get all withdrawals for a gym (no limit) for total calculation
  Stream<List<WithdrawalModel>> getAllWithdrawals(String gymId) {
    return _firestore
        .collection('withdrawals')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snaps) => snaps.docs
            .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get partner withdrawals with pagination
  Stream<List<WithdrawalModel>> getPartnerWithdrawals(String gymId, {int limit = 5}) {
    return _firestore
        .collection('withdrawals')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map(
          (snaps) {
            final list = snaps.docs
                .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
                .toList();
            // Client-side Sort: timestamp DESC
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return list.take(limit).toList();
          },
        );
  }

  // Admin side
  Stream<List<WithdrawalModel>> getPendingWithdrawals() {
    return _firestore
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snaps) {
            final list = snaps.docs
                .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
                .toList();
            // Client-side Sort: timestamp ASC
            list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            return list;
          },
        );
  }

  Stream<List<WithdrawalModel>> getHistoryWithdrawals() {
    return _firestore
        .collection('withdrawals')
        .where('status', whereIn: ['paid', 'rejected'])
        .snapshots()
        .map(
          (snaps) {
            final list = snaps.docs
                .map((doc) => WithdrawalModel.fromMap(doc.id, doc.data()))
                .toList();
            // Client-side Sort: timestamp DESC
            list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            return list;
          },
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              ...data,
              'earnedAmount': data['partnerEarned'],
              'userName': 'Hội viên Vpass', 
            };
          }).toList();
          
          // Client-side Sort: timestamp DESC
          list.sort((a, b) {
            final tsA = a['timestamp'] as Timestamp?;
            final tsB = b['timestamp'] as Timestamp?;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });
          
          return list.take(limit).toList();
        });
  }

  Future<GymModel?> getGym(String gymId) async {
    final doc = await _firestore.collection('gyms').doc(gymId).get();
    if (!doc.exists) return null;
    return GymModel.fromMap(doc.id, doc.data()!);
  }
}
