import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/deposit_request_model.dart';

class DepositRepository {
  final FirebaseFirestore _firestore;

  DepositRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> requestDeposit(String userId, String userName, double amount, {String? adminNote}) async {
    final docRef = _firestore.collection('deposit_requests').doc();
    final request = DepositRequestModel(
      id: docRef.id,
      userId: userId,
      userName: userName,
      amount: amount,
      status: 'pending',
      timestamp: DateTime.now(),
      adminNote: adminNote,
    );
    await docRef.set(request.toMap());
  }

  Stream<List<DepositRequestModel>> getUserDepositRequests(String userId) {
    return _firestore
        .collection('deposit_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snaps) {
          final list = snaps.docs.map((doc) => DepositRequestModel.fromMap(doc.id, doc.data())).toList();
          // Client-side Sort: timestamp DESC
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Stream<List<DepositRequestModel>> getPendingDepositRequests() {
    return _firestore
        .collection('deposit_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snaps) {
          final list = snaps.docs.map((doc) => DepositRequestModel.fromMap(doc.id, doc.data())).toList();
          // Client-side Sort: timestamp ASC
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        });
  }

  Stream<List<DepositRequestModel>> getHistoryDepositRequests() {
    return _firestore
        .collection('deposit_requests')
        .where('status', whereIn: ['approved', 'rejected'])
        .snapshots()
        .map((snaps) {
          final list = snaps.docs.map((doc) => DepositRequestModel.fromMap(doc.id, doc.data())).toList();
          // Client-side Sort: timestamp DESC
          list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return list;
        });
  }

  Future<void> approveDeposit(String requestId, String userId, double amount) async {
    final batch = _firestore.batch();

    // 1. Update request status
    final requestRef = _firestore.collection('deposit_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'approved',
      'processedAt': FieldValue.serverTimestamp(),
    });

    // 2. Increase user balance
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'wallet.balance': FieldValue.increment(amount),
    });

    // 3. Create transaction log
    final txRef = _firestore.collection('transactions').doc();
    batch.set(txRef, {
      'userId': userId,
      'amount': amount,
      'type': 'deposit',
      'timestamp': FieldValue.serverTimestamp(),
      'description': 'Nạp tiền qua yêu cầu (Đã duyệt)',
    });

    await batch.commit();
  }

  Future<void> rejectDeposit(String requestId, String adminNote) async {
    await _firestore.collection('deposit_requests').doc(requestId).update({
      'status': 'rejected',
      'adminNote': adminNote,
      'processedAt': FieldValue.serverTimestamp(),
    });
  }
}
