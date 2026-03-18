import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/card_model.dart';

class CardRepository {
  final FirebaseFirestore _firestore;

  CardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CardModel>> getUserCards(String uid) {
    return _firestore
        .collection('cards')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CardModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> updateCardStatus(
    String cardId,
    String status, {
    String? reason,
  }) async {
    await _firestore.collection('cards').doc(cardId).update({
      'status': status,
      'inactivatedAt': FieldValue.serverTimestamp(),
      'expiryReason': ?reason,
    });
  }

  Stream<List<CardModel>> getAllCardsStream() {
    return _firestore.collection('cards').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CardModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
