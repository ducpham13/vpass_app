import 'package:cloud_firestore/cloud_firestore.dart';

class DepositRequestModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final String status; // pending, approved, rejected
  final DateTime timestamp;
  final String? adminNote;
  final DateTime? processedAt;

  DepositRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.status,
    required this.timestamp,
    this.adminNote,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'status': status,
      'timestamp': timestamp,
      'adminNote': adminNote,
      'processedAt': processedAt,
    };
  }

  factory DepositRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return DepositRequestModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      adminNote: map['adminNote'],
      processedAt: map['processedAt'] != null ? (map['processedAt'] as Timestamp).toDate() : null,
    );
  }
}
