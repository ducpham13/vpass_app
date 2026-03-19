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
    final List<String> gymIds = [];
    final Map<String, String> gymToOwner = {};

    for (final email in [...customerEmails, ...gymEmails]) {
      final snap = await firestore.collection('users').where('profile.email', isEqualTo: email).get(const GetOptions(source: Source.server));
      if (snap.docs.isNotEmpty) {
        userUids[email] = snap.docs.first.id;
      }
    }

    if (userUids.isEmpty) {
      throw 'Không tìm thấy tài khoản test nào trong Firestore. Vui lòng chạy lại Seed 1.';
    }

    for (int i = 0; i < gymEmails.length; i++) {
      final email = gymEmails[i];
      final uid = userUids[email];
      if (uid == null) continue;

      final gymSnap = await firestore.collection('gyms').where('owner.uid', isEqualTo: uid).get();
      String gymId;
      if (gymSnap.docs.isEmpty) {
        gymId = firestore.collection('gyms').doc().id;
        final gym = {
          'info': {
            'name': 'Gym Seed ${i + 1}',
            'address': 'Address Seed ${i + 1}',
            'city': 'Hanoi',
            'imageUrl': 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?q=80&w=400',
            'colorIndex': i % 5,
          },
          'pricing': {'pricePerMonth': 600000.0},
          'owner': {'uid': uid, 'name': 'Gym Partner ${i + 1}', 'email': email},
          'bank': {'name': 'VPBank', 'cardNumber': '123456789', 'accountName': 'PARTNER ${i + 1}'},
          'status': 'active',
          'feeRate': 0.1,
          'createdAt': FieldValue.serverTimestamp(),
          'contract': {'openTime': '06:00', 'closeTime': '22:00'},
          'operational': {'crowdLevel': 'average', 'isClosedOverride': false},
        };
        await firestore.collection('gyms').doc(gymId).set(gym);
      } else {
        gymId = gymSnap.docs.first.id;
      }
      gymIds.add(gymId);
      gymToOwner[gymId] = uid;
    }

    if (gymIds.isEmpty) throw 'Lỗi: Không có phòng tập nào. Chạy Seed 1 trước.';

    final List<String> cardIds = [];
    for (final email in customerEmails) {
      final uid = userUids[email];
      if (uid == null) continue;
      final cardSnap = await firestore.collection('cards').where('userId', isEqualTo: uid).where('status', isEqualTo: 'active').get();
      if (cardSnap.docs.isEmpty) {
        final cardId = firestore.collection('cards').doc().id;
        final purchaseDate = DateTime.now().subtract(const Duration(days: 10)); // Current active card: 10 days ago
        await firestore.collection('cards').doc(cardId).set({
          'userId': uid,
          'type': 'membership',
          'status': 'active',
          'colorIndex': 0,
          'priceSnapshot': 5000000.0,
          'membershipPrice': 5000000.0,
          'usedValue': 200000.0, // Significant usage already
          'startDate': Timestamp.fromDate(purchaseDate),
          'endDate': Timestamp.fromDate(purchaseDate.add(const Duration(days: 30))), // Strictly 30 days
          'purchasedAt': Timestamp.fromDate(purchaseDate),
        });
        cardIds.add(cardId);
      } else {
        cardIds.add(cardSnap.docs.first.id);
      }
    }

    if (cardIds.isEmpty) throw 'Lỗi: Customer chưa có thẻ. Chạy Seed 1 trước.';

    final now = DateTime.now();
    for (int month = 0; month < 5; month++) {
      int recordsInMonth = 12 + (month % 3); // 12, 13, 14 records/month
      for (int k = 0; k < recordsInMonth; k++) {
        final randomDay = (month * 30) + (k * 2) + 1;
        final timestamp = now.subtract(Duration(days: randomDay, hours: k));
        final dateStr = "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";
        
        final cusId = userUids[customerEmails[k % customerEmails.length]]!;
        final gymId = gymIds[k % gymIds.length];
        final ownerUid = gymToOwner[gymId]!;
        final cardId = cardIds[k % cardIds.length];
        
        final batch = firestore.batch();
        batch.set(firestore.collection('revenue_logs').doc(), {
          'partnerUid': ownerUid,
          'gymId': gymId,
          'gymName': 'Gym Seed ${(k % gymIds.length) + 1}',
          'cardId': cardId,
          'buyerUid': cusId,
          'partnerEarned': 30000.0,
          'feeRate': 0.1,
          'timestamp': Timestamp.fromDate(timestamp),
          'type': 'global_checkin',
        });
        batch.set(firestore.collection('sessions').doc(), {
          'cardId': cardId, 'userId': cusId, 'gymId': gymId, 'date': dateStr,
          'timestamp': Timestamp.fromDate(timestamp), 'valueCharged': 30000.0, 'checkedInBy': gymId,
        });
        batch.set(firestore.collection('checkins').doc(), {
          'cardId': cardId, 'userId': cusId, 'userName': 'Guest ${k+1}', 'gymId': gymId,
          'gymName': 'Gym Seed ${(k % gymIds.length) + 1}', 'timestamp': Timestamp.fromDate(timestamp), 'cardType': 'membership',
        });
        await batch.commit();
      }
    }

    for (final gymId in gymIds) {
       final ownerUid = gymToOwner[gymId]!;
       // Paid withdrawal from 4 months ago
       await firestore.collection('withdrawals').add({
         'partnerUid': ownerUid, 'gymId': gymId, 'amount': 150000.0, 'status': 'paid',
         'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 125))),
         'processedAt': Timestamp.fromDate(now.subtract(const Duration(days: 124))),
         'bankInfo': {'name': 'VPBank', 'cardNumber': '123456789'},
       });
       // Pending withdrawal from 5 days ago
       await firestore.collection('withdrawals').add({
         'partnerUid': ownerUid, 'gymId': gymId, 'amount': 80000.0, 'status': 'pending',
         'timestamp': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
         'bankInfo': {'name': 'VPBank', 'cardNumber': '123456789'},
       });
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
