import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance = OwnerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
    // CHECK EXISTING PHONE ACCOUNT
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
      final Map<String, dynamic> data =
          phoneAccount.data() ??
              <String, dynamic>{};

      final dynamic existingOwnerId =
          data['ownerId'];

      if (existingOwnerId is String &&
          existingOwnerId.trim().isNotEmpty) {
        return existingOwnerId.trim();
      }
    }

    // ==========================================================
    // CREATE NEW OWNER ID
    // ==========================================================

    return _firestore.runTransaction<String>(
      (Transaction transaction) async {
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

        final DateTime now = DateTime.now();

        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        const List<String> monthCodes = [
          'J', // January
          'F', // February
          'M', // March
          'A', // April
          'Y', // May
          'U', // June
          'L', // July
          'G', // August
          'S', // September
          'O', // October
          'N', // November
          'D', // December
        ];

        final String monthCode =
            monthCodes[now.month - 1];

        const List<String> dayCodes = [
          'M', // Monday
          'T', // Tuesday
          'W', // Wednesday
          'H', // Thursday
          'F', // Friday
          'A', // Saturday
          'S', // Sunday
        ];

        final String dayCode =
            dayCodes[now.weekday - 1];

        final String serial =
            nextSerial
                .toString()
                .padLeft(4, '0');

        // Example:
        // OWN26S10001
        //
        // Actual format:
        // OWN + YY + MonthCode + DayCode + Serial

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
        // COUNTER
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
        // OWNER
        // ======================================================

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId': ownerId,
            'uid': cleanUid,
            'authUid': cleanUid,
            'phoneNumber': cleanPhone,
            'phone': cleanPhone,
            'mainPhone': cleanPhone,
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
            'uid': cleanUid,
            'authUid': cleanUid,
            'ownerId': ownerId,
            'phoneNumber': cleanPhone,
            'phone': cleanPhone,
            'mainPhone': cleanPhone,
            'role': 'owner',
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
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // FIRST: PHONE ACCOUNT
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>>
        phoneSnapshot =
        await _firestore
            .collection(_phoneAccountsCollection)
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
    // FALLBACK: OWNER SEARCH
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

    if (ownerQuery.docs.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        ownerDoc =
        ownerQuery.docs.first;

    final Map<String, dynamic> data =
        ownerDoc.data() ??
            <String, dynamic>{};

    final dynamic ownerId =
        data['ownerId'];

    if (ownerId is String &&
        ownerId.trim().isNotEmpty) {
      return ownerId.trim();
    }

    return ownerDoc.id;
  }
}
