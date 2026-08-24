// File: lib/services/qr_service.dart

import 'dart:convert';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ============================================================
/// QR DATA
/// ============================================================

class QRData {
  final String ownerId;
  final String ownerUid;

  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String qrPayload;

  const QRData({
    required this.ownerId,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
    required this.ownerPhone,
    required this.qrPayload,
  });

  factory QRData.fromMap(
    Map<String, dynamic> map, {
    String qrPayload = '',
  }) {
    return QRData(
      ownerId: (map['ownerId'] ?? '').toString().trim(),
      ownerUid: (map['ownerUid'] ?? '').toString().trim(),
      ownerName:
          (map['ownerName'] ?? 'Owner').toString().trim(),
      walkId:
          (map['walkId'] ?? '').toString().trim(),
      dogName:
          (map['dogName'] ?? 'Dog').toString().trim(),
      dogBreed:
          (map['dogBreed'] ?? '').toString().trim(),
      ownerPhone:
          (map['ownerPhone'] ?? '').toString().trim().isEmpty
              ? null
              : map['ownerPhone'].toString().trim(),
      qrPayload: qrPayload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': 'dojo_owner_qr',
      'version': 1,
      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'walkId': walkId,
      'dogName': dogName,
      'dogBreed': dogBreed,
      if (ownerPhone != null && ownerPhone!.isNotEmpty)
        'ownerPhone': ownerPhone,
    };
  }

  String encode() {
    return jsonEncode(toMap());
  }
}

/// ============================================================
/// QR SCAN STATE
/// ============================================================

class QRScanState {
  final bool scanned;
  final bool connected;

  final String ownerId;
  final String ownerUid;

  final String walkerId;
  final String walkerUid;
  final String walkerName;
  final String walkId;

  const QRScanState({
    this.scanned = false,
    this.connected = false,
    this.ownerId = '',
    this.ownerUid = '',
    this.walkerId = '',
    this.walkerUid = '',
    this.walkerName = '',
    this.walkId = '',
  });

  factory QRScanState.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    return QRScanState(
      scanned: data['scanned'] == true,
      connected: data['connected'] == true,
      ownerId:
          (data['ownerId'] ?? '').toString().trim(),
      ownerUid:
          (data['ownerUid'] ?? '').toString().trim(),
      walkerId:
          (data['walkerId'] ?? '').toString().trim(),
      walkerUid:
          (data['walkerUid'] ?? '').toString().trim(),
      walkerName:
          (data['walkerName'] ?? '').toString().trim(),
      walkId:
          (data['walkId'] ?? '').toString().trim(),
    );
  }

  @override
  String toString() {
    return 'QRScanState('
        'scanned: $scanned, '
        'connected: $connected, '
        'ownerId: $ownerId, '
        'ownerUid: $ownerUid, '
        'walkerId: $walkerId, '
        'walkerUid: $walkerUid, '
        'walkerName: $walkerName, '
        'walkId: $walkId'
        ')';
  }
}

/// ============================================================
/// QR SERVICE
/// ============================================================

class QRService {
  QRService._();

  static final QRService instance = QRService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _connections =>
          _firestore.collection('qr_connections');

  /// ==========================================================
  /// CREATE OWNER QR
  /// ==========================================================

  Future<QRData> createOwnerQR() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Owner login required.',
      );
    }

    // ==========================================================
    // FIREBASE AUTH UID
    // ==========================================================

    final String ownerUid =
        user.uid.trim();

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner account is invalid.',
      );
    }

    // ==========================================================
    // OWNER DATA
    //
    // Actual Firestore structure:
    //
    // owners/{OWNER BUSINESS ID}
    //
    // Example:
    // owners/OWN26GS0003
    // ==========================================================

    String ownerId = '';
    String ownerName = 'Owner';
    String ownerPhone = '';
    String dogName = 'Dog';
    String dogBreed = '';

    try {
      // --------------------------------------------------------
      // FIND OWNER DOCUMENT BY AUTH UID
      //
      // Actual document ID is Business ID.
      // Therefore we query authUid instead of using
      // .doc(ownerUid).
      // --------------------------------------------------------

      final QuerySnapshot<Map<String, dynamic>>
          ownerQuery =
          await _firestore
              .collection('owners')
              .where(
                'authUid',
                isEqualTo: ownerUid,
              )
              .limit(1)
              .get();

      if (ownerQuery.docs.isEmpty) {
        throw Exception(
          'Owner profile not found for this account.',
        );
      }

      final DocumentSnapshot<Map<String, dynamic>>
          ownerDoc =
          ownerQuery.docs.first;

      final Map<String, dynamic> data =
          ownerDoc.data() ??
              <String, dynamic>{};

      // --------------------------------------------------------
      // OWNER BUSINESS ID
      //
      // Document ID is the Business ID.
      // Example:
      // OWN26GS0003
      // --------------------------------------------------------

      ownerId =
          ownerDoc.id.trim();

      // Fallback to field if document ID is somehow empty.
      if (ownerId.isEmpty) {
        ownerId =
            (data['ownerId'] ?? '')
                .toString()
                .trim();
      }

      // --------------------------------------------------------
      // OWNER NAME
      // --------------------------------------------------------

      ownerName =
          (
            data['ownerName'] ??
            data['name'] ??
            data['Name'] ??
            data['Full Name'] ??
            user.displayName ??
            'Owner'
          )
              .toString()
              .trim();

      // --------------------------------------------------------
      // OWNER PHONE
      // --------------------------------------------------------

      ownerPhone =
          (
            data['phone'] ??
            data['mainPhone'] ??
            data['ownerPhone'] ??
            data['phoneNumber'] ??
            data['Mobile number'] ??
            user.phoneNumber ??
            ''
          )
              .toString()
              .trim();

      // --------------------------------------------------------
      // PET DATA
      //
      // Actual Firestore structure:
      //
      // pets: [
      //   {
      //     name: "...",
      //     breed: "...",
      //     age: "...",
      //     behaviour: "..."
      //   }
      // ]
      // --------------------------------------------------------

      final dynamic petsValue =
          data['pets'];

      if (petsValue is List &&
          petsValue.isNotEmpty) {
        final dynamic firstPet =
            petsValue.first;

        if (firstPet is Map) {
          dogName =
              (
                firstPet['name'] ??
                firstPet['Name'] ??
                'Dog'
              )
                  .toString()
                  .trim();

          dogBreed =
              (
                firstPet['breed'] ??
                firstPet['Breed'] ??
                ''
              )
                  .toString()
                  .trim();
        }
      }

      // --------------------------------------------------------
      // FALLBACK FOR OLD DOG FIELDS
      // --------------------------------------------------------

      if (dogName.isEmpty || dogName == 'Dog') {
        dogName =
            (
              data['dogName'] ??
              data['Dog Name'] ??
              data['petName'] ??
              data['Pet Name'] ??
              'Dog'
            )
                .toString()
                .trim();
      }

      if (dogBreed.isEmpty) {
        dogBreed =
            (
              data['dogBreed'] ??
              data['Dog Breed'] ??
              data['breed'] ??
              data['Breed'] ??
              ''
            )
                .toString()
                .trim();
      }
    } catch (e) {
      debugPrint(
        'Owner QR profile lookup error: $e',
      );

      rethrow;
    }

    // ==========================================================
    // VALIDATE OWNER BUSINESS ID
    // ==========================================================

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner Business ID not found.',
      );
    }

    if (ownerName.isEmpty) {
      ownerName = 'Owner';
    }

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String walkId =
        'walk_${DateTime.now().millisecondsSinceEpoch}';

    // ==========================================================
    // QR PAYLOAD
    // ==========================================================

    final Map<String, dynamic> payload = {
      'type': 'dojo_owner_qr',
      'version': 1,

      'ownerId': ownerId,
      'ownerUid': ownerUid,

      'ownerName': ownerName,

      'walkId': walkId,

      'dogName': dogName,
      'dogBreed': dogBreed,

      if (ownerPhone.isNotEmpty)
        'ownerPhone': ownerPhone,
    };

    final String qrPayload =
        jsonEncode(payload);

    // ==========================================================
    // FIRESTORE QR CONNECTION
    //
    // Document ID:
    // OWN26GS0003
    // ==========================================================

    await _connections
        .doc(ownerId)
        .set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALK
        'walkId': walkId,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // CONNECTION
        'scanned': false,
        'connected': false,

        // WALKER
        'walkerId': null,
        'walkerUid': null,
        'walkerName': null,

        // LIVE WALK
        'activeWalkId': null,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: false,
      ),
    );

    // ==========================================================
    // RETURN QR DATA
    // ==========================================================

    return QRData(
      ownerId: ownerId,
      ownerUid: ownerUid,
      ownerName: ownerName,
      walkId: walkId,
      dogName: dogName,
      dogBreed: dogBreed,
      ownerPhone:
          ownerPhone.isEmpty
              ? null
              : ownerPhone,
      qrPayload: qrPayload,
    );
  }

  /// ==========================================================
  /// CREATE NEW OWNER WALK QR
  /// ==========================================================

  Future<QRData> createOwnerWalkQR() async {
    return createOwnerQR();
  }

  /// ==========================================================
  /// WATCH WALKER SCAN
  /// ==========================================================

  Stream<QRScanState> watchScan(
    String ownerId,
  ) {
    if (ownerId.trim().isEmpty) {
      return Stream<QRScanState>.error(
        Exception(
          'Invalid owner ID.',
        ),
      );
    }

    return _connections
        .doc(ownerId.trim())
        .snapshots()
        .map(
      (
        DocumentSnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        if (!snapshot.exists) {
          return const QRScanState();
        }

        return QRScanState.fromFirestore(
          snapshot,
        );
      },
    );
  }

  /// ==========================================================
  /// WALKER CONNECT
  /// ==========================================================

  Future<void> markWalkerConnected({
    required String ownerId,
    required String walkerId,
    required String walkerUid,
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner Business ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker Business ID is required.',
      );
    }

    if (walkerUid.trim().isEmpty) {
      throw Exception(
        'Walker Firebase UID is required.',
      );
    }

    await _connections
        .doc(ownerId.trim())
        .set(
      {
        'ownerId': ownerId.trim(),

        'walkerId': walkerId.trim(),
        'walkerUid': walkerUid.trim(),
        'walkerName': walkerName.trim(),

        'scanned': true,
        'connected': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId.trim(),

        'activeWalkId':
            walkId?.trim().isNotEmpty == true
                ? walkId!.trim()
                : null,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  /// ==========================================================
  /// MARK SCANNED
  /// ==========================================================

  Future<void> markScanned({
    required String ownerId,
    required String walkerId,
    required String walkerUid,
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner Business ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker Business ID is required.',
      );
    }

    if (walkerUid.trim().isEmpty) {
      throw Exception(
        'Walker Firebase UID is required.',
      );
    }

    await _connections
        .doc(ownerId.trim())
        .set(
      {
        'ownerId': ownerId.trim(),

        'walkerId': walkerId.trim(),
        'walkerUid': walkerUid.trim(),
        'walkerName': walkerName.trim(),

        'scanned': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId.trim(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  /// ==========================================================
  /// CLEAR CONNECTION
  /// ==========================================================

  Future<void> clearConnection(
    String ownerId,
  ) async {
    if (ownerId.trim().isEmpty) {
      return;
    }

    await _connections
        .doc(ownerId.trim())
        .set(
      {
        'scanned': false,
        'connected': false,

        'walkerId': null,
        'walkerUid': null,
        'walkerName': null,

        'activeWalkId': null,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  /// ==========================================================
  /// DELETE CONNECTION
  /// ==========================================================

  Future<void> deleteConnection(
    String ownerId,
  ) async {
    if (ownerId.trim().isEmpty) {
      return;
    }

    await _connections
        .doc(ownerId.trim())
        .delete();
  }

  /// ==========================================================
  /// PARSE QR PAYLOAD
  /// ==========================================================

  static Map<String, dynamic> parsePayload(
    String rawPayload,
  ) {
    final String value =
        rawPayload.trim();

    if (value.isEmpty) {
      throw const FormatException(
        'Empty QR code.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(value);
    } catch (_) {
      throw const FormatException(
        'Invalid Dojo QR code.',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid QR payload.',
      );
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(decoded);

    final String type =
        (data['type'] ?? '')
            .toString()
            .trim();

    if (type != 'dojo_owner_qr') {
      throw const FormatException(
        'This QR code is not a Dojo Owner QR.',
      );
    }

    // ==========================================================
    // OWNER BUSINESS ID
    // ==========================================================

    final String ownerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (ownerId.isEmpty) {
      throw const FormatException(
        'Owner Business ID missing from QR.',
      );
    }

    // ==========================================================
    // OWNER FIREBASE UID
    // ==========================================================

    final String ownerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    if (ownerUid.isEmpty) {
      throw const FormatException(
        'Owner Firebase UID missing from QR.',
      );
    }

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String walkId =
        (data['walkId'] ?? '')
            .toString()
            .trim();

    if (walkId.isEmpty) {
      throw const FormatException(
        'Walk ID missing from QR.',
      );
    }

    return data;
  }

  /// ==========================================================
  /// QR DATA FROM PAYLOAD
  /// ==========================================================

  static QRData dataFromPayload(
    String rawPayload,
  ) {
    final Map<String, dynamic> data =
        parsePayload(rawPayload);

    return QRData.fromMap(
      data,
      qrPayload: rawPayload,
    );
  }
}
