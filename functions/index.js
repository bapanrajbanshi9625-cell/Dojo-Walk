const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const msg91AuthKey = defineSecret("MSG91_AUTHKEY");

exports.createFirebaseToken = onCall(
  {
    region: "us-central1",
    secrets: [msg91AuthKey],
  },
  async (request) => {
    // ============================================================
    // 1. GET MSG91 ACCESS TOKEN
    // ============================================================

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

    // ============================================================
    // 2. GET MSG91 AUTH KEY
    // ============================================================

    const authKey = msg91AuthKey.value().trim();

    if (!authKey) {
      console.error(
        "MSG91_AUTHKEY is not configured.",
      );

      throw new HttpsError(
        "failed-precondition",
        "MSG91 authentication is not configured.",
      );
    }

    // ============================================================
    // 3. VERIFY MSG91 ACCESS TOKEN
    // ============================================================

    let msg91Data;

    try {
      const body = new URLSearchParams();

      body.append(
        "authkey",
        authKey,
      );

      body.append(
        "access-token",
        accessToken,
      );

      const response = await fetch(
        "https://control.msg91.com/api/v5/widget/verifyAccessToken",
        {
          method: "POST",
          headers: {
            "Content-Type":
              "application/x-www-form-urlencoded",
          },
          body: body.toString(),
        },
      );

      const responseText = await response.text();

      let parsedResponse;

      try {
        parsedResponse = responseText
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

      msg91Data = parsedResponse;
    } catch (error) {
      if (error instanceof HttpsError) {
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

    // ============================================================
    // 4. EXTRACT VERIFIED MOBILE
    // ============================================================

    const verifiedPhone =
      extractVerifiedPhone(msg91Data);

    if (!verifiedPhone) {
      console.error(
        "MSG91 response did not contain verified phone.",
        msg91Data,
      );

      throw new HttpsError(
        "unauthenticated",
        "Unable to identify verified mobile number.",
      );
    }

    const phone =
      normalizeIndianPhone(verifiedPhone);

    if (!phone) {
      throw new HttpsError(
        "unauthenticated",
        "Invalid verified mobile number.",
      );
    }

    console.log(
      "Verified phone:",
      maskPhone(phone),
    );

    // ============================================================
    // 5. FIRESTORE
    // ============================================================

    const db = getFirestore();
    const auth = getAuth();

    // ============================================================
    // 6. FIND EXISTING ACCOUNT
    // ============================================================
    //
    // IMPORTANT:
    //
    // phoneAccounts document ID = Firebase UID
    //
    // Example:
    //
    // phoneAccounts
    //   └── Z2NE7dDvgMNpRQ68OIyGLiVstv42
    //          phone: +916294613338
    //          ownerId: OWN26GA0007
    //
    // ============================================================

    const snapshot = await db
      .collection("phoneAccounts")
      .where(
        "phone",
        "==",
        phone,
      )
      .limit(1)
      .get();

    // ============================================================
    // EXISTING ACCOUNT
    // ============================================================

    if (!snapshot.empty) {
      const phoneDoc = snapshot.docs[0];

      const phoneData =
        phoneDoc.data() || {};

      // Document ID itself is Firebase UID.
      const uid = phoneDoc.id;

      // ----------------------------------------------------------
      // Validate stored UID
      // ----------------------------------------------------------

      if (
        phoneData.uid &&
        phoneData.uid !== uid
      ) {
        console.error(
          "phoneAccounts UID mismatch.",
        );

        throw new HttpsError(
          "permission-denied",
          "Account identity mismatch.",
        );
      }

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

      // ----------------------------------------------------------
      // Owner ID
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // Check Firebase Auth user
      // ----------------------------------------------------------

      let firebaseUser;

      try {
        firebaseUser =
          await auth.getUser(uid);
      } catch (error) {
        console.error(
          "Existing Firebase user not found:",
          error,
        );

        throw new HttpsError(
          "not-found",
          "Firebase account was not found.",
        );
      }

      // ----------------------------------------------------------
      // Check owner document
      // ----------------------------------------------------------

      const ownerRef =
        db.collection("owners").doc(ownerId);

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

      // ----------------------------------------------------------
      // Validate owner identity
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // Keep phone information updated
      // ----------------------------------------------------------

      await phoneDoc.ref.set(
        {
          uid: uid,
          authUid: uid,
          ownerId: ownerId,
          phone: phone,
          phoneNumber: phone.substring(3),
          role: "owner",
          updatedAt:
            FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        },
      );

      // ----------------------------------------------------------
      // Create Firebase Custom Token
      // ----------------------------------------------------------

      const customToken =
        await auth.createCustomToken(
          uid,
          {
            ownerId: ownerId,
            role: "owner",
            phoneVerified: true,
            authProvider: "msg91",
          },
        );

      console.log(
        "Existing owner authenticated:",
        uid,
        ownerId,
      );

      return {
        success: true,
        isNewAccount: false,
        customToken: customToken,
        uid: uid,
        ownerId: ownerId,
        profileCompleted:
          ownerData.profileCompleted === true,
      };
    }

    // ============================================================
    // NEW ACCOUNT
    // ============================================================
    //
    // No account found for this verified mobile.
    //
    // Create:
    //
    // 1. Firebase Auth user
    // 2. Owner ID
    // 3. owners/{ownerId}
    // 4. phoneAccounts/{uid}
    //
    // profileCompleted = false
    //
    // ============================================================

    console.log(
      "No existing owner account found. Creating new account.",
    );

    let newFirebaseUser;

    try {
      newFirebaseUser =
        await auth.createUser({
          phoneNumber: phone,
        });
    } catch (error) {
      console.error(
        "Firebase user creation failed:",
        error,
      );

      if (
        error &&
        error.code ===
          "auth/phone-number-already-exists"
      ) {
        throw new HttpsError(
          "already-exists",
          "A Firebase account already exists for this mobile number, but its Dojo account mapping is missing.",
        );
      }

      throw new HttpsError(
        "internal",
        "Unable to create Firebase account.",
      );
    }

    const uid =
      newFirebaseUser.uid;

    // ============================================================
    // CREATE UNIQUE OWNER ID
    // ============================================================

    const ownerId =
      await createUniqueOwnerId(db);

    const ownerRef =
      db.collection("owners").doc(ownerId);

    const phoneAccountRef =
      db
        .collection("phoneAccounts")
        .doc(uid);

    // ============================================================
    // CREATE OWNER + PHONE ACCOUNT
    // ============================================================

    try {
      const batch = db.batch();

      // ----------------------------------------------------------
      // owners/{ownerId}
      // ----------------------------------------------------------

      batch.set(
        ownerRef,
        {
          ownerId: ownerId,
          authUid: uid,
          uid: uid,

          phone: phone,
          phoneNumber: phone.substring(3),

          role: "owner",

          profileCompleted: false,
          isActive: true,

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );

      // ----------------------------------------------------------
      // phoneAccounts/{uid}
      // ----------------------------------------------------------

      batch.set(
        phoneAccountRef,
        {
          uid: uid,
          authUid: uid,

          ownerId: ownerId,

          phone: phone,
          phoneNumber: phone.substring(3),

          role: "owner",

          profileCompleted: false,

          createdAt:
            FieldValue.serverTimestamp(),

          updatedAt:
            FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
    } catch (error) {
      console.error(
        "Firestore new account creation failed:",
        error,
      );

      // ----------------------------------------------------------
      // Cleanup Firebase Auth user if Firestore creation fails.
      // ----------------------------------------------------------

      try {
        await auth.deleteUser(uid);
      } catch (cleanupError) {
        console.error(
          "Firebase user cleanup failed:",
          cleanupError,
        );
      }

      throw new HttpsError(
        "internal",
        "Unable to create owner account.",
      );
    }

    // ============================================================
    // CREATE CUSTOM TOKEN FOR NEW ACCOUNT
    // ============================================================

    const customToken =
      await auth.createCustomToken(
        uid,
        {
          ownerId: ownerId,
          role: "owner",
          phoneVerified: true,
          authProvider: "msg91",
        },
      );

    console.log(
      "New owner account created:",
      uid,
      ownerId,
    );

    // ============================================================
    // RETURN
    // ============================================================

    return {
      success: true,
      isNewAccount: true,
      customToken: customToken,
      uid: uid,
      ownerId: ownerId,
      profileCompleted: false,
    };
  },
);

// ================================================================
// EXTRACT VERIFIED PHONE FROM MSG91 RESPONSE
// ================================================================

function extractVerifiedPhone(response) {
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

    response.data?.user?.mobile,
    response.data?.user?.phone,
    response.data?.user?.phoneNumber,

    response.result?.mobile,
    response.result?.phone,
    response.result?.phoneNumber,
    response.result?.identifier,
  ];

  for (const value of candidates) {
    if (
      typeof value === "string" &&
      value.trim()
    ) {
      return value.trim();
    }
  }

  return null;
}

// ================================================================
// NORMALIZE INDIAN PHONE
// ================================================================

function normalizeIndianPhone(value) {
  let phone =
    String(value)
      .trim()
      .replace(
        /[^0-9+]/g,
        "",
      );

  if (phone.startsWith("+91")) {
    phone = phone.substring(3);
  } else if (
    phone.startsWith("91") &&
    phone.length === 12
  ) {
    phone = phone.substring(2);
  }

  if (
    phone.length !== 10 ||
    !/^[6-9][0-9]{9}$/.test(phone)
  ) {
    return null;
  }

  return `+91${phone}`;
}

// ================================================================
// CREATE UNIQUE OWNER ID
// ================================================================

async function createUniqueOwnerId(db) {
  for (let attempt = 0; attempt < 10; attempt++) {
    const randomNumber =
      Math.floor(
        1000000 +
          Math.random() * 9000000,
      );

    const ownerId =
      `OWN${randomNumber}`;

    const ownerRef =
      db.collection("owners").doc(ownerId);

    const snapshot =
      await ownerRef.get();

    if (!snapshot.exists) {
      return ownerId;
    }
  }

  throw new HttpsError(
    "internal",
    "Unable to generate unique owner ID.",
  );
}

// ================================================================
// MASK PHONE FOR LOGGING
// ================================================================

function maskPhone(phone) {
  const digits =
    phone.replace(
      /[^0-9]/g,
      "",
    );

  if (digits.length < 4) {
    return "***";
  }

  return (
    `${digits.substring(0, 2)}******` +
    `${digits.substring(digits.length - 2)}`
  );
}
