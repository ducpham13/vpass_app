const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { v4: uuidv4 } = require('uuid');

const SECRET_KEY = 'VPASS_SECRET_KEY'; // Should use Firebase Secret Manager in prod

exports.handler = async (request) => {
  // Ensure the partner is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Partner must be logged in.');
  }

  const partnerUid = request.auth.uid;
  const { payload } = request.data;
  if (!payload) {
    throw new HttpsError('invalid-argument', 'QR Payload is missing.');
  }

  let decodedData;
  try {
    const jsonString = Buffer.from(payload, 'base64').toString('utf8');
    decodedData = JSON.parse(jsonString);
  } catch (e) {
    throw new HttpsError('invalid-argument', 'Invalid QR Payload format.');
  }

  const { cardId, userId, gymId, timestamp, nonce, sig } = decodedData;

  // 1. Verify HMAC Signature
  const dataString = `\${cardId}\${userId}\${timestamp}\${nonce}`;
  const hmac = crypto.createHmac('sha256', SECRET_KEY);
  hmac.update(dataString);
  const expectedSig = hmac.digest('hex');

  // Currently we just compare the raw string due to client implementation sync issues
  // Real implementation needs robust hex vs string equivalence if needed.
  // Assuming our flutter crypto outputs hex string of digest.toString()
  if (sig !== expectedSig) {
    throw new HttpsError('permission-denied', 'Invalid QR Signature.');
  }

  // 2. TTL Check (60 seconds)
  if (Date.now() - timestamp > 60000) {
    throw new HttpsError('deadline-exceeded', 'QR Code expired.');
  }

  const db = admin.firestore();

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 3. Nonce Check
      const nonceRef = db.collection('qr_nonces').doc(nonce);
      const nonceDoc = await transaction.get(nonceRef);
      if (nonceDoc.exists) {
        throw new HttpsError('already-exists', 'QR Code already used.');
      }
      
      // Mark nonce as used
      transaction.set(nonceRef, { usedAt: admin.firestore.FieldValue.serverTimestamp() });

      // 4. Validate Card
      const cardRef = db.collection('cards').doc(cardId);
      const cardDoc = await transaction.get(cardRef);
      if (!cardDoc.exists) {
        throw new HttpsError('not-found', 'Card not found.');
      }

      const cardData = cardDoc.data();
      if (cardData.status !== 'active') {
        throw new HttpsError('failed-precondition', `Card status is \${cardData.status}.`);
      }

      if (cardData.endDate.toDate() < new Date()) {
        throw new HttpsError('failed-precondition', 'Card is expired.');
      }

      // Check partner permissions & gym routing
      // If the card is a single gym pass, it must match the partner's gym.
      const partnerDoc = await transaction.get(db.collection('users').doc(partnerUid));
      const partnerData = partnerDoc.data();
      if (partnerData.role !== 'gym_partner') {
        throw new HttpsError('permission-denied', 'Only Gym Partners can check-in users.');
      }

      const scanGymId = partnerData.gymId;
      if (cardData.type === 'single' && cardData.gymId !== scanGymId) {
        throw new HttpsError('permission-denied', 'This card is not valid for this gym.');
      }

      // Check for duplicate single checkins today
      const today = new Date().toISOString().split('T')[0];
      const todaySessionQuery = db.collection('sessions')
        .where('cardId', '==', cardId)
        .where('gymId', '==', scanGymId)
        .where('date', '==', today);
        
      const sessions = await transaction.get(todaySessionQuery);
      
      let valueCharged = 0;
      if (cardData.type === 'single') {
        if (!sessions.empty) {
          throw new HttpsError('already-exists', 'User already checked in today with this single pass.');
        }
        valueCharged = 0;
      } else if (cardData.type === 'membership') {
        if (sessions.size >= 2) {
           throw new HttpsError('resource-exhausted', 'Membership max limit of 2 check-ins per day per gym reached.');
        }
        
        // Lookup gym price to calculate value Charged
        const gymDoc = await transaction.get(db.collection('gyms').doc(scanGymId));
        if (!gymDoc.exists) {
           throw new HttpsError('not-found', 'Gym configuration missing.');
        }
        const gymPricePerMonth = gymDoc.data().pricing?.pricePerMonth || 0;
        valueCharged = gymPricePerMonth / 30;

        // Check quota limits
        const limit = cardData.membershipPrice * 0.90;
        if ((cardData.usedValue + valueCharged) > limit) {
           throw new HttpsError('resource-exhausted', 'Membership quota reached. Cannot check in.');
        }

        transaction.update(cardRef, {
           usedValue: admin.firestore.FieldValue.increment(valueCharged)
        });
      }

      // 5. Write Session
      const sessionId = uuidv4();
      const sessionRef = db.collection('sessions').doc(sessionId);
      transaction.set(sessionRef, {
        cardId: cardId,
        userId: userId,
        gymId: scanGymId,
        date: today,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        valueCharged: valueCharged,
        checkedInBy: partnerUid
      });

      return { success: true, message: 'Check-in successful', cardType: cardData.type };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('internal', 'Check-in failed.', error.message);
  }
};
