import 'package:cloud_firestore/cloud_firestore.dart';

class DepositModel {
  final String txnCode; // e.g. NAP_XXXXXX_01
  final String userId;
  final double amount;
  final String date; // "YYYY-MM-DD"
  final String status; // "pending" | "confirmed" | "rejected"
  final String? confirmedBy;
  final DateTime? confirmedAt;

  DepositModel({
    required this.txnCode,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
    this.confirmedBy,
    this.confirmedAt,
  });

  factory DepositModel.fromMap(String id, Map<String, dynamic> data) {
    return DepositModel(
      txnCode: id, // id is literally the txnCode
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] ?? '',
      status: data['status'] ?? 'pending',
      confirmedBy: data['confirmedBy'],
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'date': date,
      'status': status,
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
    };
  }
}
