import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerIdService {
  OwnerIdService._();

  static final OwnerIdService instance = OwnerIdService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _phoneAccountsCollection = 'phoneAccounts';
  static const String _ownersCollection = 'owners';
  static const String _countersCollection = 'counters';
  static const String _ownerCounterDocument = 'owner';

  // ============================================================
  // PHONE NORMALIZATION
  // ============================================================

  String normalizePhone(String phoneNumber) {
    String clean = phoneNumber
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.startsWith('0091') && clean.length == 14) {
      clean = clean.substring(4);
    } else if (clean.startsWith('91') && clean.length == 12) {
      clean = clean.substring(2);
    }

    if (clean.length != 10) {
      throw Exception('Invalid Indian mobile number.');
    }

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(clean)) {
      throw Exception('Invalid Indian mobile number.');
    }

    return clean;
  }

  String fullPhone(String phoneNumber) {
    return '+91${normalizePhone(phoneNumber)}';
  }

  List<String> phoneVariants(String phoneNumber) {
    final String tenDigit = normalizePhone(phoneNumber);

    return <String>[
      tenDigit,
      '+91$tenDigit',
      '91$tenDigit',
    ];
  }

  // ============================================================
  // FIND EXISTING OWNER BY PHONE
  // ============================================================

  Future<String?> findExistingOwnerIdByPhone({
    required String phoneNumber,
  }) async {
    final List<String> variants =
        phoneVariants(phoneNumber);

    // ----------------------------------------------------------
    // 1. phoneAccounts
    // ----------------------------------------------------------

    for (final String variant in variants) {
      for (final String field in <String>[
        'phoneNumber',
        'phone',
        'mainPhone',
      ]) {
        final QuerySnapshot<Map<String, dynamic>> result =
            await _firestore
                .collection(_phoneAccountsCollection)
                .where(
                  field,
                  isEqualTo: variant,
                )
                .limit(1)
                .get();

        if (result.docs.isNotEmpty) {
          final Map<String, dynamic> data =
              result.docs.first.data();

          final String ownerId =
              (data['ownerId'] ?? '').toString().trim();

          if (ownerId.isNotEmpty) {
            return ownerId;
          }
        }
      }
    }

    // ----------------------------------------------------------
    // 2. owners
    // ----------------------------------------------------------

    for (final String variant in variants) {
      for (final String field in <String>[
        'phoneNumber',
        'phone',
        'mainPhone',
      ]) {
        final QuerySnapshot<Map<String, dynamic>> result =
            await _firestore
                .collection(_ownersCollection)
                .where(
                  field,
                  isEqualTo: variant,
                )
                .limit(1)
                .get();

        if (result.docs.isNotEmpty) {
          final DocumentSnapshot<Map<String, dynamic>> doc =
              result.docs.first;

          final Map<String, dynamic> data =
              doc.data() ?? <String, dynamic>{};

          final String ownerId =
              (data['ownerId'] ?? doc.id)
                  .toString()
                  .trim();

          if (ownerId.isNotEmpty) {
            return ownerId;
          }
        }
      }
    }

    return null;
  }

  // ============================================================
  // GET OR CREATE OWNER ID
  // ============================================================

  Future<String> getOrCreateOwnerId({
    required String uid,
    required String phoneNumber,
  }) async {
    final String cleanUid = uid.trim();
    final String cleanPhone =
        normalizePhone(phoneNumber);

    if (cleanUid.isEmpty) {
      throw Exception('Firebase UID is empty.');
    }

    // ==========================================================
    // MOST IMPORTANT CHECK:
    // PHONE FIRST
    // ==========================================================

    final String? existingOwnerId =
        await findExistingOwnerIdByPhone(
      phoneNumber: cleanPhone,
    );

    if (existingOwnerId != null &&
        existingOwnerId.trim().isNotEmpty) {
      return existingOwnerId.trim();
    }

    // ==========================================================
    // CHECK UID MAPPING
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
          phoneAccount.data() ?? <String, dynamic>{};

      final String ownerId =
          (data['ownerId'] ?? '').toString().trim();

      if (ownerId.isNotEmpty) {
        return ownerId;
      }
    }

    // ==========================================================
    // ONLY NOW CREATE NEW OWNER
    // ==========================================================

    return _firestore.runTransaction<String>(
      (Transaction transaction) async {
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

        final int nextSerial = lastSerial + 1;

        if (nextSerial > 9999) {
          throw Exception(
            'Owner ID serial limit reached.',
          );
        }

        final DateTime now = DateTime.now();

        final String year =
            (now.year % 100)
                .toString()
                .padLeft(2, '0');

        const List<String> monthCodes = <String>[
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

        const List<String> dayCodes = <String>[
          'M',
          'T',
          'W',
          'H',
          'F',
          'A',
          'S',
        ];

        final String ownerId =
            'OWN'
            '$year'
            '${monthCodes[now.month - 1]}'
            '${dayCodes[now.weekday - 1]}'
            '${nextSerial.toString().padLeft(4, '0')}';

        final DocumentReference<Map<String, dynamic>>
            ownerRef =
            _firestore
                .collection(_ownersCollection)
                .doc(ownerId);

        transaction.set(
          counterRef,
          <String, dynamic>{
            'lastSerial': nextSerial,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          ownerRef,
          <String, dynamic>{
            'ownerId': ownerId,
            'uid': cleanUid,
            'authUid': cleanUid,
            'phoneNumber': '+91$cleanPhone',
            'phone': '+91$cleanPhone',
            'mainPhone': '+91$cleanPhone',
            'role': 'owner',
            'isActive': true,
            'profileCompleted': false,
            'pets': <Map<String, dynamic>>[],
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          phoneAccountRef,
          <String, dynamic>{
            'uid': cleanUid,
            'authUid': cleanUid,
            'ownerId': ownerId,
            'phoneNumber': '+91$cleanPhone',
            'phone': '+91$cleanPhone',
            'mainPhone': '+91$cleanPhone',
            'role': 'owner',
            'profileCompleted': false,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
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
    final String cleanUid = uid.trim();

    if (cleanUid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        phoneSnapshot =
        await _firestore
            .collection(_phoneAccountsCollection)
            .doc(cleanUid)
            .get();

    if (phoneSnapshot.exists) {
      final String ownerId =
          (phoneSnapshot.data()?['ownerId'] ?? '')
              .toString()
              .trim();

      if (ownerId.isNotEmpty) {
        return ownerId;
      }
    }

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
        ownerDoc.data() ?? <String, dynamic>{};

    final String ownerId =
        (data['ownerId'] ?? ownerDoc.id)
            .toString()
            .trim();

    return ownerId.isEmpty ? null : ownerId;
  }
}
