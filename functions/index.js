const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();

const msg91AuthKey = defineSecret("MSG91_AUTHKEY");

exports.createFirebaseToken = onCall(
  {
    region: "us-central1",
    secrets: [msg91AuthKey],
  },
  async (request) => {
    // ==========================================================
    // INPUT
    // ==========================================================

    const data = request.data || {};

    const accessToken =
      typeof data.accessToken === "string"
        ? data.accessToken.trim()
        : "";

    if (!accessToken) {
      throw new HttpsError(
        "invalid-argument",
        "MSG91 access token is required.",
      );
    }

    // ==========================================================
    // MSG91 AUTH KEY
    // ==========================================================

    const authKey =
      msg91AuthKey.value().trim();

    if (!authKey) {
      console.error(
        "MSG91_AUTHKEY is not configured.",
      );

      throw new HttpsError(
        "failed-precondition",
        "MSG91 authentication is not configured.",
      );
    }

    // ==========================================================
    // VERIFY MSG91 ACCESS TOKEN
    // ==========================================================

    let msg91Data;

    try {
      const body =
        new URLSearchParams();

      body.append(
        "authkey",
        authKey,
      );

      body.append(
        "access-token",
        accessToken,
      );

      const response =
        await fetch(
          "https://control.msg91.com/api/v5/widget/verifyAccessToken",
          {
            method: "POST",
            headers: {
              "Content-Type":
                "application/x-www-form-urlencoded",
            },
            body:
              body.toString(),
          },
        );

      const responseText =
        await response.text();

      let parsedResponse;

      try {
        parsedResponse =
          responseText
            ? JSON.parse(responseText)
            : {};
      } catch (_) {
        parsedResponse = {};
      }

      if (!response.ok) {
        console.error(
          "MSG91 verification HTTP error:",
          response.status,
        );

        throw new HttpsError(
          "unauthenticated",
          "Invalid MSG91 access token.",
        );
      }

      msg91Data =
        parsedResponse;
    } catch (error) {
      if (
        error instanceof HttpsError
      ) {
        throw error;
      }

      console.error(
        "MSG91 verification failed:",
        error,
      );

      throw new HttpsError(
        "unavailable",
        "Unable to verify MSG91 authentication.",
      );
    }

    // ==========================================================
    // VERIFIED PHONE
    // ==========================================================

    const verifiedPhone =
      extractVerifiedPhone(
        msg91Data,
      );

    if (!verifiedPhone) {
      console.error(
        "MSG91 response did not contain verified phone.",
      );

      throw new HttpsError(
        "unauthenticated",
        "Unable to identify verified mobile number.",
      );
    }

    const phone =
      normalizeIndianPhone(
        verifiedPhone,
      );

    if (!phone) {
      throw new HttpsError(
        "unauthenticated",
        "Invalid verified mobile number.",
      );
    }

    // ==========================================================
    // FIRESTORE
    // ==========================================================

    const db =
      getFirestore();

    // ==========================================================
    // FIND PHONE ACCOUNT
    // ==========================================================

    const snapshot =
      await db
        .collection("phoneAccounts")
        .where(
          "phone",
          "==",
          phone,
        )
        .limit(1)
        .get();

    if (snapshot.empty) {
      throw new HttpsError(
        "not-found",
        "No Dojo owner account is linked to this mobile number.",
      );
    }

    // ==========================================================
    // EXISTING PHONE ACCOUNT
    // ==========================================================

    const phoneDoc =
      snapshot.docs[0];

    const phoneData =
      phoneDoc.data();

    // IMPORTANT:
    // Document ID is the Firebase UID.
    const uid =
      phoneDoc.id;

    // ==========================================================
    // VERIFY UID MAPPING
    // ==========================================================

    if (
      phoneData.authUid &&
      phoneData.authUid !== uid
    ) {
      console.error(
        "phoneAccounts authUid mismatch.",
      );

      throw new HttpsError(
        "permission-denied",
        "Account identity mismatch.",
      );
    }

    if (
      phoneData.uid &&
      phoneData.uid !== uid
    ) {
      console.error(
        "phoneAccounts uid mismatch.",
      );

      throw new HttpsError(
        "permission-denied",
        "Account identity mismatch.",
      );
    }

    // ==========================================================
    // OWNER ID
    // ==========================================================

    const ownerId =
      typeof phoneData.ownerId === "string"
        ? phoneData.ownerId.trim()
        : "";

    if (!ownerId) {
      throw new HttpsError(
        "failed-precondition",
        "Owner account is not linked correctly.",
      );
    }

    // ==========================================================
    // CHECK OWNER DOCUMENT
    // ==========================================================

    const ownerRef =
      db
        .collection("owners")
        .doc(ownerId);

    const ownerSnapshot =
      await ownerRef.get();

    if (!ownerSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Owner profile was not found.",
      );
    }

    const ownerData =
      ownerSnapshot.data() || {};

    // ==========================================================
    // OWNER AUTH UID VALIDATION
    // ==========================================================

    if (
      ownerData.authUid &&
      ownerData.authUid !== uid
    ) {
      console.error(
        "Owner authUid mismatch.",
      );

      throw new HttpsError(
        "permission-denied",
        "Owner identity does not match.",
      );
    }

    // ==========================================================
    // CREATE FIREBASE CUSTOM TOKEN
    // ==========================================================

    const customToken =
      await getAuth()
        .createCustomToken(
          uid,
          {
            ownerId: ownerId,
            role: "owner",
            phoneVerified: true,
            authProvider: "msg91",
          },
        );

    // ==========================================================
    // RETURN ONLY FIREBASE TOKEN
    // ==========================================================

    return {
      success: true,
      customToken: customToken,
      uid: uid,
      ownerId: ownerId,
    };
  },
);

// ============================================================
// EXTRACT VERIFIED PHONE
// ============================================================

function extractVerifiedPhone(
  response,
) {
  if (!response) {
    return null;
  }

  const candidates = [
    response.mobile,
    response.phone,
    response.phoneNumber,
    response.identifier,

    response.data?.mobile,
    response.data?.phone,
    response.data?.phoneNumber,
    response.data?.identifier,

    response.user?.mobile,
    response.user?.phone,
    response.user?.phoneNumber,
  ];

  for (
    const value of candidates
  ) {
    if (
      typeof value === "string" &&
      value.trim()
    ) {
      return value.trim();
    }
  }

  return null;
}

// ============================================================
// NORMALIZE INDIAN PHONE
// ============================================================

function normalizeIndianPhone(
  value,
) {
  let phone =
    String(value)
      .trim()
      .replace(
        /[^0-9+]/g,
        "",
      );

  if (
    phone.startsWith("+91")
  ) {
    phone =
      phone.substring(3);
  } else if (
    phone.startsWith("91") &&
    phone.length === 12
  ) {
    phone =
      phone.substring(2);
  }

  if (
    phone.length !== 10 ||
    !/^[6-9][0-9]{9}$/.test(
      phone,
    )
  ) {
    return null;
  }

  return `+91${phone}`;
}
