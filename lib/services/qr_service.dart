// File: lib/services/qr_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// QR DATA
/// ============================================================

class QRData {
  final String ownerId;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String qrPayload;

  const QRData({
    required this.ownerId,
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
  final String walkerId;
  final String walkerName;
  final String walkId;

  const QRScanState({
    this.scanned = false,
    this.connected = false,
    this.ownerId = '',
    this.walkerId = '',
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
      ownerId: (data['ownerId'] ?? '').toString(),
      walkerId: (data['walkerId'] ?? '').toString(),
      walkerName: (data['walkerName'] ?? '').toString(),
      walkId: (data['walkId'] ?? '').toString(),
    );
  }

  @override
  String toString() {
    return 'QRScanState('
        'scanned: $scanned, '
        'connected: $connected, '
        'ownerId: $ownerId, '
        'walkerId: $walkerId, '
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

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Owner account is invalid.',
      );
    }

    // ----------------------------------------------------------
    // OWNER DATA
    // ----------------------------------------------------------

    String ownerName = 'Owner';
    String ownerPhone = '';
    String dogName = 'Dog';
    String dogBreed = '';

    try {
      final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
          await _firestore
              .collection('owners')
              .doc(uid)
              .get();

      final Map<String, dynamic> data =
          ownerDoc.data() ?? <String, dynamic>{};

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

      ownerPhone =
          (
            data['ownerPhone'] ??
            data['phoneNumber'] ??
            data['Mobile number'] ??
            user.phoneNumber ??
            ''
          )
              .toString()
              .trim();

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
    } catch (_) {
      // Keep safe fallback values.
    }

    if (ownerName.isEmpty) {
      ownerName = 'Owner';
    }

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    // ----------------------------------------------------------
    // WALK ID
    // ----------------------------------------------------------

    final String walkId =
        'walk_${DateTime.now().millisecondsSinceEpoch}';

    // ----------------------------------------------------------
    // QR PAYLOAD
    // ----------------------------------------------------------

    final Map<String, dynamic> payload = {
      'type': 'dojo_owner_qr',
      'version': 1,

      'ownerId': uid,
      'ownerName': ownerName,

      'walkId': walkId,

      'dogName': dogName,
      'dogBreed': dogBreed,

      if (ownerPhone.isNotEmpty)
        'ownerPhone': ownerPhone,
    };

    final String qrPayload =
        jsonEncode(payload);

    // ----------------------------------------------------------
    // FIRESTORE CONNECTION
    // ----------------------------------------------------------

    await _connections.doc(uid).set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,

        'ownerId': uid,
        'ownerUid': uid,

        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        'walkId': walkId,

        'dogName': dogName,
        'dogBreed': dogBreed,

        'scanned': false,
        'connected': false,

        'walkerId': null,
        'walkerName': null,

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

    return QRData(
      ownerId: uid,
      ownerName: ownerName,
      walkId: walkId,
      dogName: dogName,
      dogBreed: dogBreed,
      ownerPhone:
          ownerPhone.isEmpty ? null : ownerPhone,
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
        Exception('Invalid owner ID.'),
      );
    }

    return _connections
        .doc(ownerId)
        .snapshots()
        .map(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
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
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID is required.',
      );
    }

    await _connections.doc(ownerId).set(
      {
        'ownerId': ownerId,
        'walkerId': walkerId,
        'walkerName': walkerName,

        'scanned': true,
        'connected': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId,

        'activeWalkId': walkId,

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
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID is required.',
      );
    }

    await _connections.doc(ownerId).set(
      {
        'ownerId': ownerId,
        'walkerId': walkerId,
        'walkerName': walkerName,

        'scanned': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId,

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

    await _connections.doc(ownerId).set(
      {
        'scanned': false,
        'connected': false,

        'walkerId': null,
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
        .doc(ownerId)
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
        (data['type'] ?? '').toString().trim();

    if (type != 'dojo_owner_qr') {
      throw const FormatException(
        'This QR code is not a Dojo Owner QR.',
      );
    }

    final String ownerId =
        (data['ownerId'] ?? '').toString().trim();

    if (ownerId.isEmpty) {
      throw const FormatException(
        'Owner ID missing from QR.',
      );
    }

    final String walkId =
        (data['walkId'] ?? '').toString().trim();

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
