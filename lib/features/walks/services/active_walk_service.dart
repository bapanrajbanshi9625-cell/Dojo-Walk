import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstaWalkSearchResult {
  final bool success;
  final String? requestId;
  final DateTime? expiresAt;
  final String? message;

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.message,
  });
}

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance = InstaWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const Duration searchDuration =
      Duration(minutes: 30);

  Timer? _expiryTimer;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  // ==========================================================
  // USER REF
  // ==========================================================

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final String? currentUid = uid;

    if (currentUid == null ||
        currentUid.isEmpty) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(currentUid);
  }

  // ==========================================================
  // WALK REQUESTS
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_requests');

  // ==========================================================
  // IS SEARCHING
  // ==========================================================

  Future<bool> isSearching() async {
    final DocumentReference<Map<String, dynamic>>? ref =
        _userRef;

    if (ref == null) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return false;
    }

    final bool searching =
        data['instaWalkSearching'] == true;

    if (!searching) {
      return false;
    }

    // --------------------------------------------------------
    // CHECK EXPIRY
    // --------------------------------------------------------

    final DateTime? expiresAt =
        _readDateTime(
      data['instaWalkSearchExpiresAt'],
    );

    if (expiresAt != null &&
        DateTime.now().isAfter(expiresAt)) {
      await _expireSearch();

      return false;
    }

    return true;
  }

  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<InstaWalkSearchResult> startSearch({
    required Map<String, dynamic> walkData,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult(
        success: false,
        message: 'Owner is not logged in.',
      );
    }

    final String ownerUid =
        user.uid;

    final String requestId =
        _readString(
      walkData,
      const [
        'walkId',
        'requestId',
        'id',
      ],
    ).isNotEmpty
            ? _readString(
                walkData,
                const [
                  'walkId',
                  'requestId',
                  'id',
                ],
              )
            : _walkRequests.doc().id;

    final DateTime expiresAt =
        DateTime.now().add(
      searchDuration,
    );

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        _walkRequests.doc(requestId);

    final DocumentReference<Map<String, dynamic>>
        userRef =
        _firestore
            .collection('users')
            .doc(ownerUid);

    // ========================================================
    // OWNER DATA
    // ========================================================

    final String ownerName =
        _readString(
      walkData,
      const [
        'ownerName',
        'ownername',
      ],
    );

    final String ownerPhone =
        _readString(
      walkData,
      const [
        'ownerPhone',
        'ownermobilenumber',
        'ownerMobile',
      ],
    );

    final String dogName =
        _readString(
      walkData,
      const [
        'dogName',
        'dogname',
      ],
    );

    final String dogBreed =
        _readString(
      walkData,
      const [
        'dogBreed',
        'dogbreed',
      ],
    );

    // ========================================================
    // REQUEST DATA
    // ========================================================

    final Map<String, dynamic> requestData =
        <String, dynamic>{
      ...walkData,

      'walkId': requestId,
      'requestId': requestId,

      // ------------------------------------------------------
      // OWNER
      // ------------------------------------------------------

      'ownerId':
          walkData['ownerId'] ??
              ownerUid,

      'ownerUid':
          ownerUid,

      'ownerAuthUid':
          ownerUid,

      'ownerUserId':
          ownerUid,

      'ownerName':
          ownerName,

      'ownerPhone':
          ownerPhone,

      // ------------------------------------------------------
      // DOG
      // ------------------------------------------------------

      'dogName':
          dogName,

      'dogBreed':
          dogBreed,

      // ------------------------------------------------------
      // SEARCH
      // ------------------------------------------------------

      'status':
          'searching',

      'walkType':
          'insta_walk',

      'searchActive':
          true,

      'searchStartedAt':
          FieldValue.serverTimestamp(),

      'searchExpiresAt':
          Timestamp.fromDate(
        expiresAt,
      ),

      'createdAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // ------------------------------------------------------
      // WALKER EMPTY
      // ------------------------------------------------------

      'walkerId':
          null,

      'walkerUid':
          null,
    };

    // ========================================================
    // BATCH
    // ========================================================

    final WriteBatch batch =
        _firestore.batch();

    // --------------------------------------------------------
    // walk_requests/{requestId}
    // --------------------------------------------------------

    batch.set(
      requestRef,
      requestData,
      SetOptions(
        merge: true,
      ),
    );

    // --------------------------------------------------------
    // users/{ownerUid}
    //
    // IMPORTANT:
    // App close होने पर भी ये Firestore में रहेगा.
    // --------------------------------------------------------

    batch.set(
      userRef,
      <String, dynamic>{
        'instaWalkSearching':
            true,

        'instaWalkRequestId':
            requestId,

        'instaWalkSearchStartedAt':
            FieldValue.serverTimestamp(),

        'instaWalkSearchExpiresAt':
            Timestamp.fromDate(
          expiresAt,
        ),

        'instaWalkSearchUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();

    // --------------------------------------------------------
    // LOCAL TIMER
    //
    // सिर्फ convenience है.
    // Real persistence Firestore में है.
    // --------------------------------------------------------

    _startExpiryTimer(
      expiresAt,
      requestId,
    );

    return InstaWalkSearchResult(
      success: true,
      requestId: requestId,
      expiresAt: expiresAt,
    );
  }

  // ==========================================================
  // RESTORE SEARCH
  //
  // App reopen होने पर call करना है.
  // ==========================================================

  Future<InstaWalkSearchResult?> restoreSearch() async {
    final DocumentReference<Map<String, dynamic>>? ref =
        _userRef;

    if (ref == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await ref.get();

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    final bool searching =
        data['instaWalkSearching'] == true;

    if (!searching) {
      return null;
    }

    final DateTime? expiresAt =
        _readDateTime(
      data['instaWalkSearchExpiresAt'],
    );

    final String requestId =
        data['instaWalkRequestId']
                ?.toString()
                .trim() ??
            '';

    // --------------------------------------------------------
    // NO EXPIRY
    // --------------------------------------------------------

    if (expiresAt == null) {
      await _expireSearch();

      return null;
    }

    // --------------------------------------------------------
    // EXPIRED
    // --------------------------------------------------------

    if (DateTime.now().isAfter(expiresAt)) {
      await _expireSearch();

      return null;
    }

    // --------------------------------------------------------
    // RESTORE
    // --------------------------------------------------------

    if (requestId.isNotEmpty) {
      _startExpiryTimer(
        expiresAt,
        requestId,
      );
    }

    return InstaWalkSearchResult(
      success: true,
      requestId:
          requestId.isEmpty
              ? null
              : requestId,
      expiresAt: expiresAt,
    );
  }

  // ==========================================================
  // STOP SEARCH
  //
  // ONLY MANUAL STOP SHOULD CALL THIS.
  // ==========================================================

  Future<void> stopSearch() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    _expiryTimer?.cancel();
    _expiryTimer = null;

    final DocumentReference<Map<String, dynamic>>
        userRef =
        _firestore
            .collection('users')
            .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>>
        userSnapshot =
        await userRef.get();

    final Map<String, dynamic>? userData =
        userSnapshot.data();

    final String requestId =
        userData?['instaWalkRequestId']
                ?.toString()
                .trim() ??
            '';

    final WriteBatch batch =
        _firestore.batch();

    // --------------------------------------------------------
    // USER
    // --------------------------------------------------------

    batch.set(
      userRef,
      <String, dynamic>{
        'instaWalkSearching':
            false,

        'instaWalkSearchUpdatedAt':
            FieldValue.serverTimestamp(),

        'instaWalkSearchExpiresAt':
            null,
      },
      SetOptions(
        merge: true,
      ),
    );

    // --------------------------------------------------------
    // WALK REQUEST
    // --------------------------------------------------------

    if (requestId.isNotEmpty) {
      final DocumentReference<Map<String, dynamic>>
          requestRef =
          _walkRequests.doc(requestId);

      batch.set(
        requestRef,
        <String, dynamic>{
          'status':
              'cancelled',

          'searchActive':
              false,

          'cancelledBy':
              'owner',

          'cancelledAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    }

    await batch.commit();
  }

  // ==========================================================
  // AUTO EXPIRE
  // ==========================================================

  Future<void> _expireSearch() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    _expiryTimer?.cancel();
    _expiryTimer = null;

    final DocumentReference<Map<String, dynamic>>
        userRef =
        _firestore
            .collection('users')
            .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>>
        userSnapshot =
        await userRef.get();

    final Map<String, dynamic>? data =
        userSnapshot.data();

    final String requestId =
        data?['instaWalkRequestId']
                ?.toString()
                .trim() ??
            '';

    final WriteBatch batch =
        _firestore.batch();

    // --------------------------------------------------------
    // USER
    // --------------------------------------------------------

    batch.set(
      userRef,
      <String, dynamic>{
        'instaWalkSearching':
            false,

        'instaWalkSearchUpdatedAt':
            FieldValue.serverTimestamp(),

        'instaWalkSearchExpiresAt':
            null,
      },
      SetOptions(
        merge: true,
      ),
    );

    // --------------------------------------------------------
    // REQUEST
    // --------------------------------------------------------

    if (requestId.isNotEmpty) {
      batch.set(
        _walkRequests.doc(requestId),
        <String, dynamic>{
          'status':
              'expired',

          'searchActive':
              false,

          'expiredAt':
              FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    }

    await batch.commit();
  }

  // ==========================================================
  // EXPIRY TIMER
  // ==========================================================

  void _startExpiryTimer(
    DateTime expiresAt,
    String requestId,
  ) {
    _expiryTimer?.cancel();

    final Duration remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining == Duration.zero) {
      unawaited(
        _expireSearch(),
      );

      return;
    }

    _expiryTimer =
        Timer(
      remaining,
      () {
        unawaited(
          _expireSearch(),
        );
      },
    );
  }

  // ==========================================================
  // DATE READER
  // ==========================================================

  DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ==========================================================
  // STRING READER
  // ==========================================================

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ==========================================================
  // DISPOSE SERVICE
  // ==========================================================

  void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }
}
