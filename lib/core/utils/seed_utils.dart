import 'package:cloud_firestore/cloud_firestore.dart';

class SeedUtils {
  static Future<void> seedTestData() async {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();

    // 1. Seed Partner ONE and Gym ONE
    final partner1Uid = 'gym_partner_one';
    final gym1Id = 'gym_one';
    await _seedUser(firestore, partner1Uid, 'Partner One', 'partner1@gmail.com', 'gym_partner');
    await _seedGym(firestore, gym1Id, 'Gym One Premium', partner1Uid, 'Partner One', 'partner1@gmail.com');

    // 2. Seed Partner TWO and Gym TWO
    final partner2Uid = 'gym_partner_two';
    final gym2Id = 'gym_two';
    await _seedUser(firestore, partner2Uid, 'Partner Two', 'partner2@gmail.com', 'gym_partner');
    await _seedGym(firestore, gym2Id, 'Gym Two Elite', partner2Uid, 'Partner Two', 'partner2@gmail.com');

    // 3. Seed Customers
    for (int i = 2; i <= 5; i++) {
      final cusUid = 'customer_$i';
      final cusName = 'Customer $i';
      await _seedUser(firestore, cusUid, cusName, 'cus$i@gmail.com', 'customer', balance: 2000000);
      
      // Seed history for gym 2 specifically (as requested by user)
      if (i == 2) {
        await _seedPartnerHistory(firestore, partner2Uid, gym2Id, cusUid, cusName);
      } else {
        // Just some random activity for others
        await _seedPartnerHistory(firestore, partner1Uid, gym1Id, cusUid, cusName);
      }
    }

    // 4. Seed Admin
    await _seedUser(firestore, 'admin_fixed', 'Admin User', 'admin@gmail.com', 'admin');

    // 5. Seed Deposit Requests
    await _seedDepositRequests(firestore);
  }

  static Future<void> _seedDepositRequests(FirebaseFirestore firestore) async {
    final now = DateTime.now();
    final requests = [
      {
        'userId': 'customer_2',
        'userName': 'Customer 2',
        'amount': 500000.0,
        'status': 'pending',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'adminNote': 'Nạp tiền test'
      },
      {
        'userId': 'customer_3',
        'userName': 'Customer 3',
        'amount': 1000000.0,
        'status': 'approved',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'processedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 20))),
        'adminNote': 'Đã duyệt nạp thẻ'
      },
      {
        'userId': 'customer_4',
        'userName': 'Customer 4',
        'amount': 200000.0,
        'status': 'rejected',
        'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'processedAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'adminNote': 'Sai cú pháp chuyển khoản'
      },
    ];

    for (var data in requests) {
      await firestore.collection('deposit_requests').add(data);
    }
  }

  static Future<void> _seedUser(
    FirebaseFirestore firestore,
    String uid,
    String name,
    String email,
    String role, {
    double balance = 0,
  }) async {
    await firestore.collection('users').doc(uid).set({
      'profile': {
        'name': name,
        'email': email,
        'phone': '0912345678',
        'avatar': 'https://api.dicebear.com/7.x/pixel-art/svg?seed=$name',
      },
      'wallet': {
        'balance': balance,
      },
      'role': role,
      'isLocked': false,
    });
  }

  static Future<void> _seedGym(
    FirebaseFirestore firestore,
    String id,
    String name,
    String ownerUid,
    String ownerName,
    String email,
  ) async {
    await firestore.collection('gyms').doc(id).set({
      'info': {
        'name': name,
        'address': '123 Street, District 1',
        'city': 'Hồ Chí Minh',
        'description': 'Phòng tập cao cấp với đầy đủ trang thiết bị hiện đại.',
        'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'colorIndex': 0,
      },
      'pricing': {
        'pricePerMonth': 500000.0,
      },
      'owner': {
        'uid': ownerUid,
        'name': ownerName,
        'email': email,
      },
      'bank': {
        'name': 'Vietcombank',
        'cardNumber': '1234567890',
        'accountName': ownerName,
      },
      'contract': {
        'openTime': '06:00',
        'closeTime': '22:00',
      },
      'operational': {
        'crowdLevel': 'average',
        'isClosedOverride': false,
        'lastReset': Timestamp.now(),
      },
      'feeRate': 0.1, // 10% platform fee
      'status': 'active',
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> _seedPartnerHistory(
    FirebaseFirestore firestore,
    String partnerUid,
    String gymId,
    String cusUid,
    String cusName,
  ) async {
    final now = DateTime.now();

    // 1. Seed Revenue Logs & Cards
    // Old cards (> 30 days) - Revenue Unlocked
    for (int i = 0; i < 3; i++) {
      final cardId = '${gymId}_old_card_$i';
      final boughtAt = now.subtract(const Duration(days: 40));
      
      await firestore.collection('cards').doc(cardId).set({
        'userId': cusUid,
        'gymId': gymId,
        'gymName': 'Premium Gym',
        'type': 'single',
        'status': 'active',
        'colorIndex': i % 5,
        'priceSnapshot': 500000.0,
        'usedValue': 0.0,
        'startDate': Timestamp.fromDate(boughtAt),
        'endDate': Timestamp.fromDate(boughtAt.add(const Duration(days: 30))),
        'purchasedAt': Timestamp.fromDate(boughtAt),
      });

      await firestore.collection('revenue_logs').add({
        'gymId': gymId,
        'partnerUid': partnerUid,
        'cardId': cardId,
        'partnerEarned': 450000.0,
        'buyPrice': 500000.0,
        'timestamp': Timestamp.fromDate(boughtAt),
      });
    }

    // New cards (< 30 days) - Revenue Pending
    for (int i = 0; i < 2; i++) {
      final cardId = '${gymId}_new_card_$i';
      final boughtAt = now.subtract(const Duration(days: 10));

      await firestore.collection('cards').doc(cardId).set({
        'userId': cusUid,
        'gymId': gymId,
        'gymName': 'Premium Gym',
        'type': 'single',
        'status': 'active',
        'colorIndex': (i + 3) % 5,
        'priceSnapshot': 500000.0,
        'usedValue': 0.0,
        'startDate': Timestamp.fromDate(boughtAt),
        'endDate': Timestamp.fromDate(boughtAt.add(const Duration(days: 30))),
        'purchasedAt': Timestamp.fromDate(boughtAt),
      });

      await firestore.collection('revenue_logs').add({
        'gymId': gymId,
        'partnerUid': partnerUid,
        'cardId': cardId,
        'partnerEarned': 450000.0,
        'buyPrice': 500000.0,
        'timestamp': Timestamp.fromDate(boughtAt),
      });
    }

    // EXTRA: Add one card TODAY to show up in current month Dashboard
    final todayCardId = '${gymId}_today_card';
    await firestore.collection('cards').doc(todayCardId).set({
      'userId': cusUid,
      'gymId': gymId,
      'gymName': 'Premium Gym',
      'type': 'single',
      'status': 'active',
      'colorIndex': 4,
      'priceSnapshot': 500000.0,
      'usedValue': 0.0,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
      'purchasedAt': Timestamp.fromDate(now),
    });
    await firestore.collection('revenue_logs').add({
      'gymId': gymId,
      'partnerUid': partnerUid,
      'cardId': todayCardId,
      'partnerEarned': 450000.0,
      'buyPrice': 500000.0,
      'timestamp': Timestamp.fromDate(now),
    });

    // 2. Seed Withdrawals
    final pLabel = gymId.contains('one') ? 'ONE' : 'TWO';
    // Withdrawal 1: Paid (800,000)
    await firestore.collection('withdrawals').add({
      'partnerUid': partnerUid,
      'gymId': gymId,
      'amount': 800000.0,
      'status': 'paid',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
      'bankInfo': {
        'bank': 'Vietcombank',
        'account': '1234567890',
        'name': 'PARTNER $pLabel'
      }
    });

    // Withdrawal 2: Pending (200,000)
    await firestore.collection('withdrawals').add({
      'partnerUid': partnerUid,
      'gymId': gymId,
      'amount': 200000.0,
      'status': 'pending',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      'bankInfo': {
        'bank': 'Vietcombank',
        'account': '1234567890',
        'name': 'PARTNER $pLabel'
      }
    });

    // Withdrawal 3: Rejected (1,000,000)
    await firestore.collection('withdrawals').add({
      'partnerUid': partnerUid,
      'gymId': gymId,
      'amount': 1000000.0,
      'status': 'rejected',
      'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'adminNote': 'Sai thông tin tài khoản ngân hàng.',
      'bankInfo': {
        'bank': 'Vietcombank',
        'account': '0000000000',
        'name': 'WRONG NAME'
      }
    });
  }
}
