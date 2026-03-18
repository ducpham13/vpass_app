const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.handler = async (request) => {
  // Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  // Ensure the caller is an admin
  // For Vpass MVP, we'll verify the role from user profile or custom claims
  const adminUid = request.auth.uid;
  const db = admin.firestore();
  
  const adminDoc = await db.collection('users').doc(adminUid).get();
  if (!adminDoc.exists || adminDoc.data().role !== 'super_admin') {
    throw new HttpsError('permission-denied', 'Only Super Admins can confirm deposits.');
  }

  const { txnCode } = request.data;
  if (!txnCode) {
    throw new HttpsError('invalid-argument', 'Transaction code (txnCode) is required.');
  }

  const depositRef = db.collection('deposits').doc(txnCode);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const depositDoc = await transaction.get(depositRef);

      if (!depositDoc.exists) {
        throw new HttpsError('not-found', 'Deposit transaction not found.');
      }

      const depositData = depositDoc.data();
      if (depositData.status !== 'pending') {
        throw new HttpsError('failed-precondition', 'Deposit is already processed.');
      }

      // 1. Update Deposit status
      transaction.update(depositRef, {
        status: 'confirmed',
        confirmedBy: adminUid,
        confirmedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 2. Increment user's wallet
      const userRef = db.collection('users').doc(depositData.userId);
      transaction.update(userRef, {
        'wallet.balance': admin.firestore.FieldValue.increment(depositData.amount)
      });

      return { success: true, message: `Successfully confirmed \${depositData.amount} for user \${depositData.userId}.` };
    });

    return result;
  } catch (error) {
    console.error("confirmDeposit error: ", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Transaction failed.', error.message);
  }
};
