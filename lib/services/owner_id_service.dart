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
      throw Exception('Firebase UID is empty.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception('Phone number is empty.');
    }

    // ==========================================================
    // PHONE ACCOUNT
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        phoneAccountRef =
        _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        phoneAccount =
        await phoneAccountRef.get();

    if (phoneAccount.exists) {
      final Map<String, dynamic>? data =
          phoneAccount.data();

      final dynamic existingOwnerId =
          data?['ownerId'];

      if (existingOwnerId is String &&
          existingOwnerId.trim().isNotEmpty) {
        return existingOwnerId.trim();
      }
    }

    // ==========================================================
    // CREATE NEW OWNER ID
    // ==========================================================

    return await _firestore.runTransaction<String>(
      (transaction) async {
        // ------------------------------------------------------
        // COUNTER
        // ------------------------------------------------------

        final DocumentReference<Map<String, dynamic>>
            counterRef =
            _firestore
                .collection(_countersCollection)
                .doc(_ownerCounterDocument);

        final DocumentSnapshot<Map<String, dynamic>>
            counterSnapshot =
            await transaction.get(counterRef);

        int lastSerial = 0;

        if (counterSnapshot.exists) {
          final dynamic value =
              counterSnapshot.data()?['lastSerial'];

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

        // January = J
        // February = F
        // March = M
        // April = A
        // May = Y
        // June = U
        // July = L
        // August = G
        // September = S
        // October = O
        // November = N
        // December = D

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

        // Monday = M
        // Tuesday = T
        // Wednesday = W
        // Thursday = H
        // Friday = F
        // Saturday = A
        // Sunday = S

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
        // OWN26GM0001

        final String ownerId =
            'OWN$year$monthCode$dayCode$serial';

        // ======================================================
        // OWNER DOCUMENT
        // ======================================================

        final DocumentReference<Map<String, dynamic>>
            ownerRef =
            _firestore
                .collection(_ownersCollection)
                .doc(ownerId);

        // ======================================================
        // COUNTER UPDATE
        // ======================================================

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

        // ======================================================
        // OWNER DOCUMENT
        // ======================================================

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId': ownerId,
            'authUid': cleanUid,
            'phone': cleanPhone,
            'role': 'owner',
            'isActive': true,
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

        // ======================================================
        // PHONE ACCOUNT
        // ======================================================

        transaction.set(
          phoneAccountRef,
          <String, dynamic>{
            'authUid': cleanUid,
            'phone': cleanPhone,
            'role': 'owner',
            'ownerId': ownerId,
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

      if (ownerId is String &&
          ownerId.trim().isNotEmpty) {
        return ownerId.trim();
      }
    }

    // ----------------------------------------------------------
    // FALLBACK: SEARCH OWNERS
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        ownerQuery =
        await _firestore
            .collection(_ownersCollection)
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

      if (ownerId is String &&
          ownerId.trim().isNotEmpty) {
        return ownerId.trim();
      }

      return ownerDoc.id;
    }

    return null;
  }
}
