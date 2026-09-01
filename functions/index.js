const { onCall } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

exports.createFirebaseToken = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("Authentication required.");
  }

  const uid = request.auth.uid;

  const customToken = await getAuth().createCustomToken(uid);

  return {
    success: true,
    customToken: customToken,
  };
});
