import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  final String id;
  final String partnerUid;
  final String gymId;
  final double amount;
  final String status; // 'pending', 'approved', 'paid', 'rejected'
  final DateTime timestamp;
  final Map<String, dynamic> bankInfo;
  final DateTime? processedAt;
  final String? adminNote;

  WithdrawalModel({
    required this.id,
    required this.partnerUid,
    required this.gymId,
    required this.amount,
    required this.status,
    required this.timestamp,
    required this.bankInfo,
    this.processedAt,
    this.adminNote,
  });

  factory WithdrawalModel.fromMap(String id, Map<String, dynamic> map) {
    return WithdrawalModel(
      id: id,
      partnerUid: map['partnerUid'] ?? '',
      gymId: map['gymId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      bankInfo: map['bankInfo'] ?? {},
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      adminNote: map['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerUid': partnerUid,
      'gymId': gymId,
      'amount': amount,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
      'bankInfo': bankInfo,
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'adminNote': adminNote,
    };
  }
}
