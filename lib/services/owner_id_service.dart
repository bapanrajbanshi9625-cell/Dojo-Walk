// File location:
// lib/services/owner_id_service.dart

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
  // GET OR CREATE OWNER ID
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanPhone = phoneNumber.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Firebase UID is empty.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Phone number is empty.',
      );
    }

    // ==========================================================
    // PHONE ACCOUNT
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        phoneAccountRef =
        _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid);

    // ==========================================================
    // CHECK EXISTING OWNER ID
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        phoneAccount =
        await phoneAccountRef.get();

    if (phoneAccount.exists) {
      final Map<String, dynamic>? data =
          phoneAccount.data();

      final dynamic existingOwnerId =
          data?['ownerId'];

      final dynamic existingRole =
          data?['role'];

      if (existingRole == 'owner' &&
          existingOwnerId is String &&
          existingOwnerId.trim().isNotEmpty) {
        return existingOwnerId.trim();
      }
    }

    // ==========================================================
    // CREATE NEW OWNER ID
    // ==========================================================

    return await _firestore
        .runTransaction<String>(
      (transaction) async {
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

        // ------------------------------------------------------
        // OWNER COUNTER READ
        // ------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(
          counterRef,
        );

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot
                  .data()?['lastSerial'];

          if (value is int) {
            lastSerial = value;
          } else if (value is num) {
            lastSerial = value.toInt();
          }
        }

        // ------------------------------------------------------
        // NEXT SERIAL
        // ------------------------------------------------------

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
                .padLeft(
                  2,
                  '0',
                );

        // ------------------------------------------------------
        // MONTH CODE
        // ------------------------------------------------------

        const List<String>
            monthCodes = [
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
            monthCodes[
                now.month - 1];

        // ------------------------------------------------------
        // DAY CODE
        // ------------------------------------------------------

        const List<String>
            dayCodes = [
          'M',
          'T',
          'W',
          'H',
          'F',
          'A',
          'S',
        ];

        final String dayCode =
            dayCodes[
                now.weekday - 1];

        // ------------------------------------------------------
        // SERIAL
        // ------------------------------------------------------

        final String serial =
            nextSerial
                .toString()
                .padLeft(
                  4,
                  '0',
                );

        // ======================================================
        // FINAL OWNER ID
        // ======================================================
        //
        // Example:
        //
        // OWN26GM0001
        //
        // ======================================================

        final String ownerId =
            'OWN'
            '$year'
            '$monthCode'
            '$dayCode'
            '$serial';

        // ------------------------------------------------------
        // OWNER DOCUMENT
        // ------------------------------------------------------

        final DocumentReference<
                Map<String, dynamic>>
            ownerRef =
            _firestore
                .collection(
                  _ownersCollection,
                )
                .doc(ownerId);

        // ======================================================
        // UPDATE COUNTER
        // ======================================================

        transaction.set(
          counterRef,
          <String, dynamic>{
            'lastSerial':
                nextSerial,
            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ======================================================
        // CREATE OWNER DOCUMENT
        // ======================================================

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId':
                ownerId,

            'authUid':
                cleanUid,

            'phone':
                cleanPhone,

            'ownerName':
                '',

            'fullName':
                '',

            'address':
                '',

            'pets':
                <Map<String, dynamic>>[],

            'role':
                'owner',

            'isActive':
                true,

            'profileCompleted':
                false,

            'createdAt':
                FieldValue
                    .serverTimestamp(),

            'updatedAt':
                FieldValue
                    .serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ======================================================
        // PHONE ACCOUNT
        // ======================================================

        transaction.set(
          phoneAccountRef,
          <String, dynamic>{
            'authUid':
                cleanUid,

            'phone':
                cleanPhone,

            'role':
                'owner',

            'ownerId':
                ownerId,

            'profileCompleted':
                false,

            'updatedAt':
                FieldValue
                    .serverTimestamp(),
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
  // GET EXISTING OWNER ID
  // ============================================================

  Future<String?> getExistingOwnerId({
    required String uid,
  }) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // FIRST: PHONE ACCOUNT
    // ----------------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>
        phoneSnapshot =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid)
            .get();

    if (phoneSnapshot.exists) {
      final Map<String, dynamic>? data =
          phoneSnapshot.data();

      final dynamic ownerId =
          data?['ownerId'];

      if (ownerId is String &&
          ownerId.trim().isNotEmpty) {
        return ownerId.trim();
      }
    }

    // ----------------------------------------------------------
    // FALLBACK: OWNERS QUERY
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
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

    if (ownerQuery.docs.isEmpty) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        ownerDocument =
        ownerQuery.docs.first;

    final Map<String, dynamic>?
        ownerData =
        ownerDocument.data();

    final dynamic ownerId =
        ownerData?['ownerId'];

    if (ownerId is String &&
        ownerId.trim().isNotEmpty) {
      return ownerId.trim();
    }

    // Document ID fallback
    if (ownerDocument.id
        .trim()
        .isNotEmpty) {
      return ownerDocument.id.trim();
    }

    return null;
  }
}
