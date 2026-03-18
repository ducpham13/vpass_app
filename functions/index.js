const { onRequest } = require("firebase-functions/v2/https");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

const purchaseCard = require("./src/purchaseCard");
const confirmDeposit = require("./src/confirmDeposit");
const checkin = require("./src/checkin");

// Setup v2 callable functions
exports.purchaseCard = onCall((request) => purchaseCard.handler(request));
exports.confirmDeposit = onCall((request) => confirmDeposit.handler(request));
exports.checkin = onCall((request) => checkin.handler(request));
