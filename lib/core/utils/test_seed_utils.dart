import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class TestSeedUtils {
  static Future<void> seedStep1_Accounts() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final List<Map<String, String>> accounts = [
      {'email': 'admin@gmail.com', 'role': 'super_admin', 'name': 'Vpass Admin'},
      {'email': 'cus1@gmail.com', 'role': 'customer', 'name': 'Customer 1'},
      {'email': 'cus2@gmail.com', 'role': 'customer', 'name': 'Customer 2'},
      {'email': 'cus3@gmail.com', 'role': 'customer', 'name': 'Customer 3'},
      {'email': 'gym1@gmail.com', 'role': 'gym_partner', 'name': 'Gym Partner 1'},
      {'email': 'gym2@gmail.com', 'role': 'gym_partner', 'name': 'Gym Partner 2'},
      {'email': 'gym3@gmail.com', 'role': 'gym_partner', 'name': 'Gym Partner 3'},
    ];

    const String password = '111111';

    for (final account in accounts) {
      final email = account['email']!;
      final role = account['role']!;
      final name = account['name']!;

      try {
        UserCredential? cred;
        try {
          cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            cred = await auth.signInWithEmailAndPassword(email: email, password: password);
          } else {
            rethrow;
          }
        }

        if (cred.user != null) {
          final uid = cred.user!.uid;
          final userModel = UserModel(
            uid: uid,
            name: name,
            phone: '0123456789',
            email: email,
            avatar: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=$name',
            balance: role == 'customer' ? 1000000 : 0,
            role: role,
          );

          await firestore.collection('users').doc(uid).set(userModel.toMap());
          print('Successfully seeded user: $email');
        }
        await auth.signOut();
        // Give Auth/Firestore a small breather
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        throw 'Lỗi khi tạo tài khoản $email: $e';
      }
    }

    // Final Verification
    final verifySnap = await firestore.collection('users').limit(1).get();
    if (verifySnap.docs.isEmpty) {
      throw 'Lỗi nghiêm trọng: Đã chạy Seed 1 nhưng Firestore vẫn trống trơn. Kiểm tra kết nối mạng hoặc quyền của Firebase.';
    }
  }

  static Future<void> seedStep2_HistoricalData() async {
    final firestore = FirebaseFirestore.instance;
    final List<String> customerEmails = ['cus1@gmail.com', 'cus2@gmail.com', 'cus3@gmail.com'];
    final List<String> gymEmails = ['gym1@gmail.com', 'gym2@gmail.com', 'gym3@gmail.com'];

    final Map<String, String> userUids = {};
    for (final email in [...customerEmails, ...gymEmails]) {
      final snap = await firestore.collection('users').where('profile.email', isEqualTo: email).get();
      if (snap.docs.isNotEmpty) {
        userUids[email] = snap.docs.first.id;
      }
    }

    if (userUids.length < 6) {
      throw 'Không đủ 6 tài khoản test (3 cus, 3 gym). Vui lòng chạy Seed 1 trước.';
    }

    // 1. Create 3 Gyms for each Partner
    final Map<String, List<String>> partnerGyms = {};
    final Map<String, double> gymPrices = {};

    for (int i = 0; i < gymEmails.length; i++) {
      final email = gymEmails[i];
      final uid = userUids[email]!;
      final List<String> gymsForThisPartner = [];
      
      final cities = ['Hà Nội', 'Đà Nẵng', 'TP. Hồ Chí Minh'];
      final city = cities[i];

      for (int j = 1; j <= 3; j++) {
        final gymNum = (i + 1) * 100 + j; // 101, 102, 103, 201...
        final gymId = 'gym_$gymNum';
        final price = 600000.0 + (j * 100000.0); // 700k, 800k, 900k
        
        await firestore.collection('gyms').doc(gymId).set({
          'info': {
            'name': 'Gym $gymNum',
            'address': '${j * 12} Đường số $j, Quận ${i + 1}',
            'city': city,
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=400',
            'colorIndex': (i + j) % 5,
          },
          'pricing': {'pricePerMonth': price},
          'owner': {'uid': uid, 'name': 'Chủ Gym ${i + 1}', 'email': email},
          'bank': {'name': 'VPBank', 'cardNumber': '999$gymNum', 'accountName': 'DOI TAC $gymNum'},
          'status': 'active',
          'feeRate': 0.1,
          'createdAt': Timestamp.fromDate(DateTime(2025, 8, 15)),
          'contract': {'openTime': '05:30', 'closeTime': '22:30'},
          'operational': {'crowdLevel': 'average', 'isClosedOverride': false},
        });
        gymsForThisPartner.add(gymId);
        gymPrices[gymId] = price;
      }
      partnerGyms[uid] = gymsForThisPartner;
    }

    // 2. Clear previous history for these users to avoid confusion
    // (We'll skip this to keep it simple, or user can run Seed 3)

    // 3. Generate Historical Data from Sep 2025 to Mar 2026
    final startMonth = DateTime(2025, 9, 1);
    final now = DateTime.now();
    
    // Initial Deposits (15M each)
    for (final email in customerEmails) {
      final uid = userUids[email]!;
      await firestore.collection('deposits').add({
        'userId': uid,
        'amount': 15000000.0,
        'status': 'approved',
        'timestamp': Timestamp.fromDate(DateTime(2025, 9, 1, 10, 0)),
        'processedAt': Timestamp.fromDate(DateTime(2025, 9, 1, 10, 30)),
        'bankReference': 'SEED_START',
      });
      await firestore.collection('users').doc(uid).update({'balance': 15000000.0});
    }

    // Monthly Simulation
    DateTime currentMonth = startMonth;
    while (currentMonth.isBefore(now)) {
      final isLastMonth = currentMonth.year == now.year && currentMonth.month == now.month;
      
      for (int i = 0; i < customerEmails.length; i++) {
        final email = customerEmails[i];
        final uid = userUids[email]!;
        final partnerUid = userUids[gymEmails[i]]!; // Each cus uses their partner's gyms
        final gyms = partnerGyms[partnerUid]!;
        
        // frequency: 20 -> 24 -> 28 -> 32 -> 36 -> 40
        final monthDiff = (currentMonth.year - startMonth.year) * 12 + (currentMonth.month - startMonth.month);
        final sessionCount = isLastMonth ? 20 : (20 + (monthDiff * 4)).clamp(20, 40);
        
        // A. Buy VIP Card
        final cardId = 'card_${email.split('@')[0]}_${currentMonth.year}_${currentMonth.month}';
        final cardStartDate = currentMonth;
        final cardEndDate = currentMonth.add(Duration(days: 30));
        final vipPrice = 5000000.0;
        final vipLimit = vipPrice * 0.95;
        
        double usedValue = 0;
        
        await firestore.collection('cards').doc(cardId).set({
          'userId': uid,
          'type': 'membership',
          'status': (isLastMonth && cardEndDate.isAfter(now)) ? 'active' : 'expired',
          'colorIndex': i,
          'priceSnapshot': vipPrice,
          'membershipPrice': vipPrice,
          'usedValue': 0, // Will update after sessions
          'startDate': Timestamp.fromDate(cardStartDate),
          'endDate': Timestamp.fromDate(cardEndDate),
          'purchasedAt': Timestamp.fromDate(cardStartDate.add(const Duration(hours: 1))),
        });
        
        // Record purchase transaction
        await firestore.collection('users').doc(uid).update({'balance': FieldValue.increment(-vipPrice)});

        // B. Generate Sessions
        final batch = firestore.batch();
        for (int s = 0; s < sessionCount; s++) {
          final gymId = gyms[s % gyms.length];
          final gymName = 'Gym ${gymId.split('_')[1]}';
          final sessionPrice = gymPrices[gymId]! / 30;
          
          if (usedValue + sessionPrice > vipLimit) break;
          
          final day = (s * (30 / sessionCount)).floor() + 1;
          final timestamp = currentMonth.add(Duration(days: day, hours: 17 + (s % 4)));
          if (timestamp.isAfter(now)) break;
          
          final dateStr = "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
          
          usedValue += sessionPrice;

          final revenueLogRef = firestore.collection('revenue_logs').doc();
          batch.set(revenueLogRef, {
            'partnerUid': partnerUid,
            'gymId': gymId,
            'gymName': gymName,
            'cardId': cardId,
            'buyerUid': uid,
            'partnerEarned': sessionPrice,
            'feeRate': 0.1,
            'timestamp': Timestamp.fromDate(timestamp),
            'type': 'global_checkin',
          });

          final sessionRef = firestore.collection('sessions').doc();
          batch.set(sessionRef, {
            'cardId': cardId,
            'userId': uid,
            'gymId': gymId,
            'date': dateStr,
            'timestamp': Timestamp.fromDate(timestamp),
            'valueCharged': sessionPrice,
            'checkedInBy': gymId,
          });

          final checkinRef = firestore.collection('checkins').doc();
          batch.set(checkinRef, {
            'cardId': cardId,
            'userId': uid,
            'userName': 'Hội viên ${i + 1}',
            'gymId': gymId,
            'gymName': gymName,
            'timestamp': Timestamp.fromDate(timestamp),
            'cardType': 'membership',
          });
        }
        await batch.commit();
        
        // Update card's final usedValue for the month
        await firestore.collection('cards').doc(cardId).update({'usedValue': usedValue});
      }
      
      // C. Monthly Settlements (for previous month)
      if (!isLastMonth) {
        for (final partnerEmail in gymEmails) {
          final pid = userUids[partnerEmail]!;
          final settlementAmount = 2000000.0 + (currentMonth.month * 500000.0); // Rough estimate for demo
          
          await firestore.collection('settlements').add({
            'partnerUid': pid,
            'amount': settlementAmount,
            'status': 'paid',
            'periodStart': Timestamp.fromDate(currentMonth),
            'periodEnd': Timestamp.fromDate(currentMonth.add(const Duration(days: 30))),
            'timestamp': Timestamp.fromDate(currentMonth.add(const Duration(days: 31, hours: 10))),
            'paidAt': Timestamp.fromDate(currentMonth.add(const Duration(days: 32, hours: 14))),
            'bankInfo': {'name': 'VPBank', 'cardNumber': '999_SETTLE'},
          });
        }
      }

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
  }

  static Future<int> seedStep3_WipeAll() async {
    final firestore = FirebaseFirestore.instance;
    int itemsDeleted = 0;
    final collections = [
      'users', 'gyms', 'cards', 'sessions', 'checkins', 'revenue_logs',
      'withdrawals', 'deposits', 'settlements', 'notifications', 'used_qr_nonces',
    ];

    for (final col in collections) {
      bool hasMore = true;
      while (hasMore) {
        final snaps = await firestore.collection(col).limit(450).get(const GetOptions(source: Source.server));
        if (snaps.docs.isEmpty) { hasMore = false; break; }
        final batch = firestore.batch();
        for (var doc in snaps.docs) { batch.delete(doc.reference); itemsDeleted++; }
        await batch.commit();
        if (snaps.docs.length < 450) hasMore = false;
      }
    }
    return itemsDeleted;
  }
}
