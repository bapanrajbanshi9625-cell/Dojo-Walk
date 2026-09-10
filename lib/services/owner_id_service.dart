import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance =
      OwnerIdService._();

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
  // NORMALIZE PHONE
  // ============================================================

  String normalizePhone(
    String phoneNumber,
  ) {
    String value =
        phoneNumber.trim();

    value = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // 0091XXXXXXXXXX
    if (value.startsWith('0091') &&
        value.length == 14) {
      value = value.substring(4);
    }

    // 91XXXXXXXXXX
    if (value.startsWith('91') &&
        value.length == 12) {
      value = value.substring(2);
    }

    if (value.length != 10) {
      throw ArgumentError(
        'Invalid Indian mobile number.',
      );
    }

    if (!RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(value)) {
      throw ArgumentError(
        'Invalid Indian mobile number.',
      );
    }

    return value;
  }

  // ============================================================
  // FULL PHONE
  // ============================================================

  String fullPhone(
    String phoneNumber,
  ) {
    final String clean =
        normalizePhone(phoneNumber);

    return '+91$clean';
  }

  // ============================================================
  // PHONE VARIANTS
  // ============================================================

  List<String> phoneVariants(
    String phoneNumber,
  ) {
    final String clean =
        normalizePhone(phoneNumber);

    return <String>[
      clean,
      '+91$clean',
      '91$clean',
    ];
  }

  // ============================================================
  // FIND EXISTING OWNER ID BY PHONE
  // ============================================================
  //
  // IMPORTANT:
  //
  // We intentionally search ONLY phoneAccounts here.
  //
  // Do NOT query:
  //
  // owners.where(phoneNumber == ...)
  //
  // because normal signed-in owner users are not allowed
  // to perform arbitrary phone-based queries on owners.
  //
  // Existing-owner login is already handled securely by
  // Render backend + Firebase custom token.
  //
  // For a NEW owner, phoneAccounts will normally be empty,
  // so the code safely continues to create a new owner.
  //
  // ============================================================

  Future<String?> findExistingOwnerIdByPhone({
    required String phoneNumber,
  }) async {
    final String cleanPhone =
        normalizePhone(phoneNumber);

    final List<String> variants =
        phoneVariants(cleanPhone);

    debugPrint(
      'OWNER ID PHONE SEARCH STARTED: $cleanPhone',
    );

    for (final String variant in variants) {
      for (final String field in <String>[
        'phoneNumber',
        'phone',
        'mainPhone',
      ]) {
        final QuerySnapshot<
            Map<String, dynamic>> query =
            await _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .where(
                  field,
                  isEqualTo: variant,
                )
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          continue;
        }

        final Map<String, dynamic> data =
            query.docs.first.data();

        final String ownerId =
            (data['ownerId'] ?? '')
                .toString()
                .trim();

        if (ownerId.isNotEmpty) {
          debugPrint(
            'EXISTING OWNER ID FOUND FROM PHONE ACCOUNT: '
            '$ownerId',
          );

          return ownerId;
        }
      }
    }

    debugPrint(
      'NO OWNER ID FOUND IN PHONE ACCOUNTS',
    );

    return null;
  }

  // ============================================================
  // GET EXISTING OWNER ID BY FIREBASE UID
  // ============================================================

  Future<String?> getExistingOwnerId({
    required String uid,
  }) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    debugPrint(
      'CHECKING EXISTING OWNER ID FOR UID: $cleanUid',
    );

    // ----------------------------------------------------------
    // 1. PHONE ACCOUNT DOCUMENT
    // ----------------------------------------------------------

    final DocumentSnapshot<
        Map<String, dynamic>> phoneAccount =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .doc(cleanUid)
            .get();

    if (phoneAccount.exists) {
      final Map<String, dynamic> data =
          phoneAccount.data() ??
              <String, dynamic>{};

      final String ownerId =
          (data['ownerId'] ?? '')
              .toString()
              .trim();

      if (ownerId.isNotEmpty) {
        debugPrint(
          'EXISTING OWNER ID FOUND FROM UID MAPPING: '
          '$ownerId',
        );

        return ownerId;
      }
    }

    // ----------------------------------------------------------
    // 2. OWNER DOCUMENT BY authUid
    //
    // This query is intentionally constrained to the
    // authenticated UID.
    //
    // It is NOT a phone query.
    // ----------------------------------------------------------

    final QuerySnapshot<
        Map<String, dynamic>> ownerQuery =
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
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
          ownerQuery.docs.first;

      final Map<String, dynamic> data =
          doc.data() ??
              <String, dynamic>{};

      final String ownerId =
          (data['ownerId'] ??
                  doc.id)
              .toString()
              .trim();

      if (ownerId.isNotEmpty) {
        debugPrint(
          'EXISTING OWNER ID FOUND FROM OWNER UID: '
          '$ownerId',
        );

        return ownerId;
      }
    }

    debugPrint(
      'NO EXISTING OWNER FOUND FOR UID: $cleanUid',
    );

    return null;
  }

  // ============================================================
  // GET OR CREATE OWNER ID
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid =
        uid.trim();

    if (cleanUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-user',
        message: 'Firebase UID is empty.',
      );
    }

    final String cleanPhone =
        normalizePhone(phoneNumber);

    final String fullPhoneNumber =
        '+91$cleanPhone';

    debugPrint(
      'GET OR CREATE OWNER ID',
    );

    debugPrint(
      'UID: $cleanUid',
    );

    debugPrint(
      'PHONE: $fullPhoneNumber',
    );

    // ==========================================================
    // 1. PHONE ACCOUNT LOOKUP
    // ==========================================================
    //
    // IMPORTANT:
    // This no longer queries owners by phone.
    //
    // Existing accounts are already handled by the backend
    // before Profile Setup.
    //
    // ==========================================================

    final String? existingByPhone =
        await findExistingOwnerIdByPhone(
      phoneNumber: cleanPhone,
    );

    if (existingByPhone != null &&
        existingByPhone.trim().isNotEmpty) {
      debugPrint(
        'OWNER ID ALREADY EXISTS: '
        '$existingByPhone',
      );

      return existingByPhone.trim();
    }

    // ==========================================================
    // 2. CHECK UID MAPPING
    // ==========================================================

    final String? existingByUid =
        await getExistingOwnerId(
      uid: cleanUid,
    );

    if (existingByUid != null &&
        existingByUid.trim().isNotEmpty) {
      debugPrint(
        'OWNER ID FOUND BY UID: '
        '$existingByUid',
      );

      return existingByUid.trim();
    }

    // ==========================================================
    // 3. CREATE NEW OWNER ID
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> counterRef =
        _firestore
            .collection(
              _countersCollection,
            )
            .doc(
              _ownerCounterDocument,
            );

    final String ownerId =
        await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ COUNTER FIRST
        // ------------------------------------------------------

        final DocumentSnapshot<
            Map<String, dynamic>> counterSnapshot =
            await transaction.get(
          counterRef,
        );

        final Map<String, dynamic> counterData =
            counterSnapshot.data() ??
                <String, dynamic>{};

        final int currentSerial =
            _readInt(
          counterData['lastSerial'],
        );

        final int nextSerial =
            currentSerial + 1;

        // ------------------------------------------------------
        // GENERATE OWNER ID
        // ------------------------------------------------------

        final DateTime now =
            DateTime.now();

        final String year =
            now.year
                .toString()
                .substring(2);

        final String monthCode =
            _monthCode(
          now.month,
        );

        final String weekdayCode =
            _weekdayCode(
          now.weekday,
        );

        final String serial =
            nextSerial
                .toString()
                .padLeft(
                  4,
                  '0',
                );

        final String generatedOwnerId =
            'OWN'
            '$year'
            '$monthCode'
            '$weekdayCode'
            '$serial';

        // ------------------------------------------------------
        // COUNTER UPDATE
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
        // CREATE OWNER DOCUMENT
        // ------------------------------------------------------

        final DocumentReference<
            Map<String, dynamic>> ownerRef =
            _firestore
                .collection(
                  _ownersCollection,
                )
                .doc(
                  generatedOwnerId,
                );

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId':
                generatedOwnerId,
            'uid':
                cleanUid,
            'authUid':
                cleanUid,
            'phone':
                fullPhoneNumber,
            'mainPhone':
                fullPhoneNumber,
            'phoneNumber':
                fullPhoneNumber,
            'role':
                'owner',
            'profileCompleted':
                false,
            'isActive':
                true,
            'pets':
                <Map<String, dynamic>>[],
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
        // CREATE PHONE ACCOUNT MAPPING
        // ------------------------------------------------------

        final DocumentReference<
            Map<String, dynamic>> phoneAccountRef =
            _firestore
                .collection(
                  _phoneAccountsCollection,
                )
                .doc(
                  cleanUid,
                );

        transaction.set(
          phoneAccountRef,
          <String, dynamic>{
            'uid':
                cleanUid,
            'authUid':
                cleanUid,
            'ownerId':
                generatedOwnerId,
            'phone':
                fullPhoneNumber,
            'mainPhone':
                fullPhoneNumber,
            'phoneNumber':
                fullPhoneNumber,
            'role':
                'owner',
            'profileCompleted':
                false,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        return generatedOwnerId;
      },
    );

    debugPrint(
      'NEW OWNER ID CREATED: $ownerId',
    );

    return ownerId;
  }

  // ============================================================
  // INTEGER HELPER
  // ============================================================

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
            value.trim(),
          ) ??
          0;
    }

    return 0;
  }

  // ============================================================
  // MONTH CODE
  // ============================================================

  String _monthCode(
    int month,
  ) {
    const List<String> codes =
        <String>[
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

    if (month < 1 ||
        month > 12) {
      return 'J';
    }

    return codes[month - 1];
  }

  // ============================================================
  // WEEKDAY CODE
  // ============================================================

  String _weekdayCode(
    int weekday,
  ) {
    const List<String> codes =
        <String>[
      'M',
      'T',
      'W',
      'H',
      'F',
      'A',
      'S',
    ];

    if (weekday < 1 ||
        weekday > 7) {
      return 'M';
    }

    return codes[weekday - 1];
  }
}
