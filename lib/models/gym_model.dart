import 'package:cloud_firestore/cloud_firestore.dart';

class GymModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String description;
  final String imageUrl;
  final double pricePerMonth;
  final String ownerUid; // Restored for linking to partner account
  final String ownerName;
  final String partnerEmail;
  final String bankName;
  final String bankCardNumber;
  final String bankAccountName;
  final double feeRate; // default 0.05
  final String status; // "active" | "inactive" | "pending"
  final DateTime? createdAt;
  final int colorIndex;
  final String? rejectionReason;

  // Contract Timing
  final String openTime; // e.g., "05:30"
  final String closeTime; // e.g., "21:30"

  // Daily Operational Data (can be overridden by partner)
  final String crowdLevel; // "quiet" | "average" | "busy"
  final bool isClosedOverride;
  final String? emergencyNotice;
  final DateTime? lastOperationalReset;

  GymModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.description,
    required this.imageUrl,
    required this.pricePerMonth,
    required this.ownerUid,
    required this.ownerName,
    required this.partnerEmail,
    required this.bankName,
    required this.bankCardNumber,
    required this.bankAccountName,
    required this.feeRate,
    required this.status,
    this.createdAt,
    this.openTime = '06:00',
    this.closeTime = '22:00',
    this.crowdLevel = 'average',
    this.isClosedOverride = false,
     this.emergencyNotice,
    this.lastOperationalReset,
    this.colorIndex = 0,
    this.rejectionReason,
  });

  factory GymModel.fromMap(String id, Map<String, dynamic> data) {
    final info = data['info'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final owner = data['owner'] as Map<String, dynamic>? ?? {};
    final bank = data['bank'] as Map<String, dynamic>? ?? {};

    final contract = data['contract'] as Map<String, dynamic>? ?? {};
    final operational = data['operational'] as Map<String, dynamic>? ?? {};

    final lastReset = (operational['lastReset'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    bool needsReset = false;
    
    if (lastReset != null) {
      if (lastReset.year != now.year || lastReset.month != now.month || lastReset.day != now.day) {
        needsReset = true;
      }
    }

    return GymModel(
      id: id,
      name: info['name'] ?? '',
      address: info['address'] ?? '',
      city: info['city'] ?? '',
      description: info['description'] ?? '',
      imageUrl: info['imageUrl'] ?? '',
      pricePerMonth: (pricing['pricePerMonth'] ?? 0).toDouble(),
      ownerUid: owner['uid'] ?? '',
      ownerName: owner['name'] ?? '',
      partnerEmail: owner['email'] ?? '',
      bankName: bank['name'] ?? '',
      bankCardNumber: bank['cardNumber'] ?? '',
      bankAccountName: bank['accountName'] ?? owner['name'] ?? '', // Fallback to owner name
      feeRate: (data['feeRate'] ?? 0.1).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      openTime: contract['openTime'] ?? '06:00',
      closeTime: contract['closeTime'] ?? '22:00',
      crowdLevel: needsReset ? 'average' : (operational['crowdLevel'] ?? 'average'),
      isClosedOverride: needsReset ? false : (operational['isClosedOverride'] ?? false),
      emergencyNotice: needsReset ? null : operational['emergencyNotice'],
      lastOperationalReset: needsReset ? now : lastReset,
      colorIndex: info['colorIndex'] ?? 0,
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'info': {
        'name': name,
        'address': address,
        'city': city,
        'description': description,
        'imageUrl': imageUrl,
        'colorIndex': colorIndex,
      },
      'pricing': {
        'pricePerMonth': pricePerMonth,
      },
      'owner': {
        'uid': ownerUid,
        'name': ownerName,
        'email': partnerEmail,
      },
      'bank': {
        'name': bankName,
        'cardNumber': bankCardNumber,
        'accountName': bankAccountName,
      },
      'contract': {
        'openTime': openTime,
        'closeTime': closeTime,
      },
      'operational': {
        'crowdLevel': crowdLevel,
        'isClosedOverride': isClosedOverride,
        'emergencyNotice': emergencyNotice,
        if (lastOperationalReset != null) 'lastReset': Timestamp.fromDate(lastOperationalReset!),
      },
      'feeRate': feeRate,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  GymModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? description,
    String? imageUrl,
    double? pricePerMonth,
    String? ownerUid,
    String? ownerName,
    String? partnerEmail,
    String? bankName,
    String? bankCardNumber,
    String? bankAccountName,
    double? feeRate,
    String? status,
    DateTime? createdAt,
    String? openTime,
    String? closeTime,
    String? crowdLevel,
    bool? isClosedOverride,
    String? emergencyNotice,
    DateTime? lastOperationalReset,
    int? colorIndex,
    String? rejectionReason,
  }) {
    return GymModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      bankName: bankName ?? this.bankName,
      bankCardNumber: bankCardNumber ?? this.bankCardNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      feeRate: feeRate ?? this.feeRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      crowdLevel: crowdLevel ?? this.crowdLevel,
      isClosedOverride: isClosedOverride ?? this.isClosedOverride,
      emergencyNotice: emergencyNotice ?? this.emergencyNotice,
      lastOperationalReset: lastOperationalReset ?? this.lastOperationalReset,
      colorIndex: colorIndex ?? this.colorIndex,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory GymModel.empty() => GymModel(
        id: '',
        name: '',
        address: '',
        city: '',
        description: '',
        imageUrl: '',
        pricePerMonth: 0,
        ownerUid: '',
        ownerName: '',
        partnerEmail: '',
        bankName: '',
        bankCardNumber: '',
        bankAccountName: '',
        feeRate: 0,
        status: 'pending',
      );
}
