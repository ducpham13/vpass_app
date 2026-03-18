import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id;
  final String userId;
  final String? gymId;
  final String type; // "single" | "membership"
  final String status; // "active" | "expired" | "superseded"
  final int colorIndex; // 0-4
  final double priceSnapshot;
  final double? membershipPrice; // Only for membership
  final double usedValue; // Only for membership
  final DateTime startDate;
  final DateTime endDate;
  final DateTime purchasedAt;
  final String? expiryReason; // e.g., "Upgraded to Global Membership"
  final DateTime? inactivatedAt;

  CardModel({
    required this.id,
    required this.userId,
    this.gymId,
    required this.type,
    required this.status,
    required this.colorIndex,
    required this.priceSnapshot,
    this.membershipPrice,
    this.usedValue = 0,
    required this.startDate,
    required this.endDate,
    required this.purchasedAt,
    this.expiryReason,
    this.inactivatedAt,
  });

  factory CardModel.fromMap(String id, Map<String, dynamic> data) {
    return CardModel(
      id: id,
      userId: data['userId'] ?? '',
      gymId: data['gymId'],
      type: data['type'] ?? 'single',
      status: data['status'] ?? 'active',
      colorIndex: data['colorIndex'] ?? 0,
      priceSnapshot: (data['priceSnapshot'] ?? 0).toDouble(),
      membershipPrice: data['membershipPrice'] != null ? (data['membershipPrice']).toDouble() : null,
      usedValue: (data['usedValue'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      purchasedAt: (data['purchasedAt'] as Timestamp).toDate(),
      expiryReason: data['expiryReason'],
      inactivatedAt: data['inactivatedAt'] != null ? (data['inactivatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (gymId != null) 'gymId': gymId,
      'type': type,
      'status': status,
      'colorIndex': colorIndex,
      'priceSnapshot': priceSnapshot,
      if (membershipPrice != null) 'membershipPrice': membershipPrice,
      'usedValue': usedValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      if (expiryReason != null) 'expiryReason': expiryReason,
      if (inactivatedAt != null) 'inactivatedAt': Timestamp.fromDate(inactivatedAt!),
    };
  }

  bool get isSingle => type == 'single';
  bool get isMembership => type == 'membership';
  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
  bool get isExpired => status == 'expired' || status == 'superseded' || endDate.isBefore(DateTime.now());
}
