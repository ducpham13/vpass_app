import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/gym_model.dart';
import '../../models/card_model.dart';
import 'package:uuid/uuid.dart';

class GymRepository {
  final FirebaseFirestore _firestore;

  GymRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<GymModel>> getAvailableGyms() {
    return _firestore
        .collection('gyms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<GymModel>> getAllGyms() {
    return _firestore
        .collection('gyms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addGym(GymModel gym) async {
    final docRef = _firestore.collection('gyms').doc();
    final newGym = gym.copyWith(
      id: docRef.id,
      status: 'pending', // Force pending on creation
      createdAt: DateTime.now(),
    );
    await docRef.set(newGym.toMap());
  }

  Future<void> updateGym(GymModel gym) async {
    // 1. Get the current gym status to see if it's changing to inactive
    final oldGymDoc = await _firestore.collection('gyms').doc(gym.id).get();
    final oldStatus = oldGymDoc.data()?['status'];

    await _firestore.collection('gyms').doc(gym.id).update(gym.toMap());

    // 2. If changing to inactive or rejected, refund all active cards
    if ((gym.status == 'inactive' || gym.status == 'rejected') && 
        (oldStatus != 'inactive' && oldStatus != 'rejected')) {
      
      final activeCards = await _firestore
          .collection('cards')
          .where('gymId', isEqualTo: gym.id)
          .where('status', isEqualTo: 'active')
          .get();

      for (var cardDoc in activeCards.docs) {
        final cardData = cardDoc.data();
        final userId = cardData['userId'] as String;
        final cardId = cardDoc.id;
        final refundAmount = (cardData['priceSnapshot'] ?? 0).toDouble();
        final feeRate = (gym.feeRate > 0) ? gym.feeRate : 0.10; // Default platform fee
        final partnerReversalAmount = refundAmount * (1 - feeRate);

        // Perform refund in a transaction
        await _firestore.runTransaction((transaction) async {
          final userRef = _firestore.collection('users').doc(userId);
          final cardRef = cardDoc.reference;
          
          // 1. Refund 100% to user wallet
          transaction.update(userRef, {
            'wallet.balance': FieldValue.increment(refundAmount),
          });

          // 2. Mark card as expired
          transaction.update(cardRef, {
            'status': 'expired',
            'expiryReason': 'Phòng tập ngừng hoạt động',
            'inactivatedAt': FieldValue.serverTimestamp(),
          });

          // 3. Record refund transaction for user
          final transRef = _firestore.collection('transactions').doc();
          transaction.set(transRef, {
            'userId': userId,
            'gymId': gym.id,
            'amount': refundAmount,
            'type': 'refund',
            'reason': 'Hoàn tiền do phòng tập ngừng hoạt động',
            'timestamp': FieldValue.serverTimestamp(),
          });

          // 4. Reverse partner earnings (deduct from Pending)
          // We create a negative revenue_log so it naturally reduces their total/available balance
          final revenueLogRef = _firestore.collection('revenue_logs').doc();
          transaction.set(revenueLogRef, {
            'partnerUid': gym.ownerUid,
            'gymId': gym.id,
            'gymName': gym.name,
            'cardId': cardId,
            'buyerUid': userId,
            'buyPrice': -refundAmount,
            'partnerEarned': -partnerReversalAmount,
            'feeRate': feeRate,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'refund_reversal',
          });
        });
      }
    }
  }

  Stream<List<GymModel>> getPartnerGyms(String uid) {
    return _firestore
        .collection('gyms')
        .where('owner.uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GymModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> approveGym(String gymId, {double? feeRate}) async {
    final Map<String, dynamic> data = {'status': 'active'};
    if (feeRate != null) {
      data['feeRate'] = feeRate;
    }
    await _firestore.collection('gyms').doc(gymId).update(data);
  }

  Future<bool> purchaseCard(String uid, GymModel gym) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (!userDoc.exists) return false;

        final currentBalance = (userDoc.data()?['wallet']?['balance'] ?? 0).toDouble();
        if (currentBalance < gym.pricePerMonth) {
          throw Exception("Insufficient balance");
        }

        // 1. Deduct balance
        transaction.update(userDoc.reference, {
          'wallet.balance': FieldValue.increment(-gym.pricePerMonth),
        });

        // 2. Create card
        final cardId = const Uuid().v4();
        final cardRef = _firestore.collection('cards').doc(cardId);
        
        final now = DateTime.now();
        final expiry = now.add(const Duration(days: 30));

        final newCard = CardModel(
          id: cardId,
          userId: uid,
          gymId: gym.id,
          gymName: gym.name,
          type: 'membership',
          status: 'active',
          colorIndex: (gym.name.length) % 5, // Simple deterministic color
          priceSnapshot: gym.pricePerMonth,
          membershipPrice: gym.pricePerMonth,
          usedValue: 0,
          startDate: now,
          endDate: expiry,
          purchasedAt: now,
        );

        transaction.set(cardRef, newCard.toMap());
        
        // 3. Calculate Partner Revenue (Purchase price * (1 - feeRate))
        // The user wants revenue recorded immediately on purchase for "thẻ thường"
        final partnerShare = gym.pricePerMonth * (1 - gym.feeRate);
        final revenueLogRef = _firestore.collection('revenue_logs').doc();
        transaction.set(revenueLogRef, {
          'partnerUid': gym.ownerUid,
          'gymId': gym.id,
          'gymName': gym.name,
          'cardId': cardId,
          'buyerUid': uid,
          'buyPrice': gym.pricePerMonth,
          'partnerEarned': partnerShare,
          'feeRate': gym.feeRate,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'purchase_card',
        });

        // 4. Record customer transaction
        final transRef = _firestore.collection('transactions').doc();
        transaction.set(transRef, {
          'userId': uid,
          'gymId': gym.id,
          'amount': -gym.pricePerMonth,
          'type': 'purchase',
          'timestamp': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchaseGlobalCard(String uid) async {
    const double globalPrice = 500000; // Fixed price for Vpass Global
    try {
      // 1. Find all currently active cards for this user
      final activeCardsQuery = await _firestore
          .collection('cards')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .get();

      return await _firestore.runTransaction((transaction) async {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (!userDoc.exists) return false;

        final currentBalance = (userDoc.data()?['wallet']?['balance'] ?? 0).toDouble();
        if (currentBalance < globalPrice) {
          throw Exception("Insufficient balance");
        }

        // 1. Deduct balance
        transaction.update(userDoc.reference, {
          'wallet.balance': FieldValue.increment(-globalPrice),
        });

        // 2. Expire all existing cards (No refund as per requirement)
        for (var doc in activeCardsQuery.docs) {
          transaction.update(doc.reference, {
            'status': 'expired',
            'expiryReason': 'Upgraded to Global Membership',
            'inactivatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Create Global Card
        final cardId = const Uuid().v4();
        final cardRef = _firestore.collection('cards').doc(cardId);
        
        final now = DateTime.now();
        final expiry = now.add(const Duration(days: 30));

        final newCard = CardModel(
          id: cardId,
          userId: uid,
          gymId: null, // Global Card
          gymName: 'Vpass Global Member',
          type: 'membership',
          status: 'active',
          colorIndex: 2, // Purple/Nebula color index
          priceSnapshot: globalPrice,
          membershipPrice: globalPrice,
          usedValue: 0,
          startDate: now,
          endDate: expiry,
          purchasedAt: now,
        );

        transaction.set(cardRef, newCard.toMap());
        
        // 3a. Record 5% platform fee for VIP Card upfront
        final platformFee = globalPrice * 0.05;
        final revenueLogRef = _firestore.collection('revenue_logs').doc();
        transaction.set(revenueLogRef, {
          'partnerUid': 'PLATFORM', // Special identifier for upfront fee
          'gymId': 'PLATFORM_VIP',
          'gymName': 'Vpass Platform Fee',
          'cardId': cardId,
          'buyerUid': uid,
          'buyPrice': globalPrice,
          'partnerEarned': platformFee, // This is platform profit
          'feeRate': 1.0, // 100% of this log is profit
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'purchase_global_fee',
        });
        
        // 4. Record customer transaction
        final transRef = _firestore.collection('transactions').doc();
        transaction.set(transRef, {
          'userId': uid,
          'amount': -globalPrice,
          'type': 'purchase_global',
          'description': 'Mua Thẻ Vpass Global (Đa phòng)',
          'timestamp': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }
}
