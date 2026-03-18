const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { v4: uuidv4 } = require('uuid');

exports.handler = async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in to purchase a card.');
  }

  const { type, gymId, colorIndex, priceSnapshot } = request.data;
  const uid = request.auth.uid;

  if (!type || !['single', 'membership'].includes(type)) {
    throw new HttpsError('invalid-argument', 'Invalid card type specified.');
  }

  if (typeof priceSnapshot !== 'number' || priceSnapshot <= 0) {
    throw new HttpsError('invalid-argument', 'Invalid price.');
  }

  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  
  try {
    const cardId = uuidv4();
    const result = await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User profile not found.');
      }

      const userData = userDoc.data();
      const currentBalance = userData.wallet?.balance || 0;

      if (currentBalance < priceSnapshot) {
        throw new HttpsError('failed-precondition', 'Insufficient balance. Please deposit funds.');
      }

      // 1. Deduct balance from user
      transaction.update(userRef, {
        'wallet.balance': currentBalance - priceSnapshot
      });

      // 2. Create the Card
      const cardRef = db.collection('cards').doc(cardId);
      const now = admin.firestore.FieldValue.serverTimestamp();
      
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + 30); // 30 days validity

      const cardData = {
        userId: uid,
        gymId: gymId || null,
        type: type,
        status: 'active',
        colorIndex: colorIndex || 0,
        priceSnapshot: priceSnapshot,
        usedValue: 0,
        startDate: admin.firestore.Timestamp.fromDate(startDate),
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        purchasedAt: now
      };

      if (type === 'membership') {
        cardData.membershipPrice = priceSnapshot;
      }

      transaction.set(cardRef, cardData);

      return { success: true, cardId: cardId, newBalance: currentBalance - priceSnapshot };
    });

    return result;
  } catch (error) {
    console.error("purchaseCard error: ", error);
    // Re-throw HttpsError to the client
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Transaction failed.', error.message);
  }
};
