import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance =
      OwnerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _ownersCollection =
      'owners';

  static const String _countersCollection =
      'counters';

  static const String _ownerCounterDocument =
      'owner';

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  String _normalizePhone(String phoneNumber) {
    String clean = phoneNumber
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.startsWith('91') &&
        clean.length == 12) {
      clean = clean.substring(2);
    }

    if (clean.length != 10) {
      throw Exception(
        'Please enter a valid 10-digit mobile number.',
      );
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(clean)) {
      throw Exception(
        'Please enter a valid Indian mobile number.',
      );
    }

    return clean;
  }

  // ============================================================
  // PHONE FORMATS
  // ============================================================

  String _fullPhone(String cleanPhone) {
    return '+91$cleanPhone';
  }

  // ============================================================
  // GET OR CREATE OWNER ID
  // ============================================================
  ///
  /// IMPORTANT:
  ///
  /// Phone number is the PRIMARY identity.
  ///
  /// Same phone number:
  ///     -> Same Owner ID
  ///
  /// New phone number:
  ///     -> New Owner ID
  ///
  /// Firebase UID is NOT used as the primary identity.
  ///
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanPhone =
        _normalizePhone(phoneNumber);

    if (cleanUid.isEmpty) {
      throw Exception(
        'Firebase UID is empty.',
      );
    }

    final String fullPhone =
        _fullPhone(cleanPhone);

    // ==========================================================
    // 1. FIND EXISTING ACCOUNT BY PHONE
    // ==========================================================

    QuerySnapshot<Map<String, dynamic>>
        phoneQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phone',
              isEqualTo: cleanPhone,
            )
            .limit(1)
            .get();

    // ==========================================================
    // ALSO CHECK +91 FORMAT
    // ==========================================================

    if (phoneQuery.docs.isEmpty) {
      phoneQuery =
          await _firestore
              .collection(
                _phoneAccountsCollection,
              )
              .where(
                'phone',
                isEqualTo: fullPhone,
              )
              .limit(1)
              .get();
    }

    // ==========================================================
    // ALSO CHECK phoneNumber FIELD
    // ==========================================================

    if (phoneQuery.docs.isEmpty) {
      phoneQuery =
          await _firestore
              .collection(
                _phoneAccountsCollection,
              )
              .where(
                'phoneNumber',
                isEqualTo: fullPhone,
              )
              .limit(1)
              .get();
    }

    // ==========================================================
    // EXISTING PHONE FOUND
    // ==========================================================

    if (phoneQuery.docs.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>>
          existingDoc =
          phoneQuery.docs.first;

      final Map<String, dynamic> data =
          existingDoc.data() ??
              <String, dynamic>{};

      final dynamic existingOwnerId =
          data['ownerId'];

      if (existingOwnerId != null &&
          existingOwnerId
              .toString()
              .trim()
              .isNotEmpty) {
        final String ownerId =
            existingOwnerId
                .toString()
                .trim();

        // ------------------------------------------------------
        // IMPORTANT:
        // Existing Owner ID is preserved.
        // We only reconnect the current Firebase UID.
        // ------------------------------------------------------

        await existingDoc.reference.set(
          <String, dynamic>{
            'uid': cleanUid,
            'authUid': cleanUid,
            'ownerId': ownerId,
            'phone': cleanPhone,
            'phoneNumber': fullPhone,
            'mainPhone': fullPhone,
            'role': 'owner',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // Also update the UID document.
        // This is important after reinstall / new anonymous UID.
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            currentUidRef =
            _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .doc(cleanUid);

        await currentUidRef.set(
          <String, dynamic>{
            'uid': cleanUid,
            'authUid': cleanUid,
            'ownerId': ownerId,
            'phone': cleanPhone,
            'phoneNumber': fullPhone,
            'mainPhone': fullPhone,
            'role': 'owner',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // DO NOT CREATE A NEW OWNER.
        // ------------------------------------------------------

        return ownerId;
      }
    }

    // ==========================================================
    // 2. FALLBACK:
    // SEARCH OWNERS BY PHONE
    // ==========================================================

    QuerySnapshot<Map<String, dynamic>>
        ownerPhoneQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phone',
              isEqualTo: cleanPhone,
            )
            .limit(1)
            .get();

    if (ownerPhoneQuery.docs.isEmpty) {
      ownerPhoneQuery =
          await _firestore
              .collection(
                _ownersCollection,
              )
              .where(
                'phone',
                isEqualTo: fullPhone,
              )
              .limit(1)
              .get();
    }

    if (ownerPhoneQuery.docs.isEmpty) {
      ownerPhoneQuery =
          await _firestore
              .collection(
                _ownersCollection,
              )
              .where(
                'phoneNumber',
                isEqualTo: fullPhone,
              )
              .limit(1)
              .get();
    }

    // ==========================================================
    // EXISTING OWNER FOUND
    // ==========================================================

    if (ownerPhoneQuery.docs.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>>
          ownerDoc =
          ownerPhoneQuery.docs.first;

      final Map<String, dynamic> ownerData =
          ownerDoc.data() ??
              <String, dynamic>{};

      final dynamic ownerIdValue =
          ownerData['ownerId'];

      final String ownerId =
          ownerIdValue != null &&
                  ownerIdValue
                      .toString()
                      .trim()
                      .isNotEmpty
              ? ownerIdValue
                  .toString()
                  .trim()
              : ownerDoc.id;

      // --------------------------------------------------------
      // Reconnect account to current UID.
      // --------------------------------------------------------

      await _firestore
          .collection(
            _phoneAccountsCollection,
          )
          .doc(cleanUid)
          .set(
        <String, dynamic>{
          'uid': cleanUid,
          'authUid': cleanUid,
          'ownerId': ownerId,
          'phone': cleanPhone,
          'phoneNumber': fullPhone,
          'mainPhone': fullPhone,
          'role': 'owner',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // Update owner UID but DO NOT touch profileCompleted.
      // --------------------------------------------------------

      await ownerDoc.reference.set(
        <String, dynamic>{
          'ownerId': ownerId,
          'uid': cleanUid,
          'authUid': cleanUid,
          'phone': cleanPhone,
          'phoneNumber': fullPhone,
          'role': 'owner',
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // DO NOT CREATE NEW OWNER.
      // --------------------------------------------------------

      return ownerId;
    }

    // ==========================================================
    // 3. NEW PHONE NUMBER
    // ==========================================================
    //
    // Only here are we allowed to create a new Owner ID.
    //
    // ==========================================================

    return await _firestore.runTransaction<String>(
      (transaction) async {
        // ------------------------------------------------------
        // Re-check phone inside transaction.
        //
        // This prevents duplicate Owner IDs if two requests
        // happen at nearly the same time.
        // ------------------------------------------------------

        final QuerySnapshot<Map<String, dynamic>>
            existingAccounts =
            await _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .where(
                  'phone',
                  isEqualTo: cleanPhone,
                )
                .limit(1)
                .get();

        if (existingAccounts.docs.isNotEmpty) {
          final Map<String, dynamic> data =
              existingAccounts.docs.first.data();

          final dynamic existingOwnerId =
              data['ownerId'];

          if (existingOwnerId != null &&
              existingOwnerId
                  .toString()
                  .trim()
                  .isNotEmpty) {
            return existingOwnerId
                .toString()
                .trim();
          }
        }

        // ------------------------------------------------------
        // COUNTER
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            counterRef =
            _firestore
                .collection(
                  _countersCollection,
                )
                .doc(
                  _ownerCounterDocument,
                );

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(
          counterRef,
        );

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot.data()?[
                  'lastSerial'];

          if (value is int) {
            lastSerial = value;
          } else if (value is num) {
            lastSerial = value.toInt();
          }
        }

        final int nextSerial =
            lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Owner ID serial limit reached.',
          );
        }

        // ------------------------------------------------------
        // DATE
        // ------------------------------------------------------

        final DateTime now =
            DateTime.now();

        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        const List<String> monthCodes = [
          'J',
          'F',
          'M',
          'A',
          'Y',
          'U',
          'L',
          'G',
          'S',
          'O',
          'N',
          'D',
        ];

        final String monthCode =
            monthCodes[now.month - 1];

        const List<String> dayCodes = [
          'M',
          'T',
          'W',
          'H',
          'F',
          'A',
          'S',
        ];

        final String dayCode =
            dayCodes[now.weekday - 1];

        final String serial =
            nextSerial
                .toString()
                .padLeft(4, '0');

        // Example:
        // OWN26SM0001

        final String ownerId =
            'OWN$year$monthCode$dayCode$serial';

        // ------------------------------------------------------
        // REFERENCES
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            ownerRef =
            _firestore
                .collection(
                  _ownersCollection,
                )
                .doc(ownerId);

        final DocumentReference<Map<String, dynamic>>
            phoneAccountRef =
            _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .doc(cleanUid);

        // ------------------------------------------------------
        // COUNTER
        // ------------------------------------------------------

        transaction.set(
          counterRef,
          <String, dynamic>{
            'lastSerial': nextSerial,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId': ownerId,
            'uid': cleanUid,
            'authUid': cleanUid,
            'phone': cleanPhone,
            'phoneNumber': fullPhone,
            'mainPhone': fullPhone,
            'role': 'owner',
            'isActive': true,

            // New account only.
            'profileCompleted': false,

            'pets': <Map<String, dynamic>>[],

            'createdAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // PHONE ACCOUNT
        // ------------------------------------------------------

        transaction.set(
          phoneAccountRef,
          <String, dynamic>{
            'uid': cleanUid,
            'authUid': cleanUid,
            'ownerId': ownerId,
            'phone': cleanPhone,
            'phoneNumber': fullPhone,
            'mainPhone': fullPhone,
            'role': 'owner',

            // New account only.
            'profileCompleted': false,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        return ownerId;
      },
    );
  }

  // ============================================================
  // GET EXISTING OWNER ID BY UID
  // ============================================================

  Future<String?> getExistingOwnerId({
    required String uid,
  }) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        phoneSnapshot =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid)
            .get();

    if (phoneSnapshot.exists) {
      final dynamic ownerId =
          phoneSnapshot.data()?['ownerId'];

      if (ownerId != null &&
          ownerId.toString().trim().isNotEmpty) {
        return ownerId.toString().trim();
      }
    }

    // ----------------------------------------------------------
    // OWNER FALLBACK BY AUTH UID
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        ownerQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'authUid',
              isEqualTo: cleanUid,
            )
            .limit(1)
            .get();

    if (ownerQuery.docs.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>>
          ownerDoc =
          ownerQuery.docs.first;

      final dynamic ownerId =
          ownerDoc.data()?['ownerId'];

      if (ownerId != null &&
          ownerId.toString().trim().isNotEmpty) {
        return ownerId.toString().trim();
      }

      return ownerDoc.id;
    }

    return null;
  }
}
