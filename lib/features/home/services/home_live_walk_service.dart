import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/home_live_walk.dart';
import 'home_owner_service.dart';

class HomeLiveWalkService {
  HomeLiveWalkService._();

  static final HomeLiveWalkService instance =
      HomeLiveWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final HomeOwnerService _ownerService =
      HomeOwnerService.instance;

  static const String collection = 'active_walks';

  // ============================================================
  // LIVE WALK STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> stream() async* {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    yield* _firestore
        .collection(collection)
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .snapshots();
  }

  // ============================================================
  // MAIN NAVIGATION COMPATIBILITY STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      liveWalkStream() async* {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    yield* _firestore
        .collection(collection)
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .snapshots();
  }

  // ============================================================
  // CURRENT LIVE WALK
  // ============================================================

  Future<HomeLiveWalk?> getCurrentWalk() async {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(collection)
            .where(
              'ownerId',
              isEqualTo: ownerId,
            )
            .limit(20)
            .get();

    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
      in snapshot.docs
    ) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      if (!_isLive(data)) {
        continue;
      }

      return HomeLiveWalk.fromFirestore(
        doc.id,
        data,
      );
    }

    return null;
  }

  // ============================================================
  // MAIN NAVIGATION DATA
  // ============================================================

  Map<String, dynamic>? getLiveWalkData(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
      in snapshot.docs
    ) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      if (!_isLive(data)) {
        continue;
      }

      data['_documentId'] = doc.id;

      final String walkId = _string(
        data['walkId'] ??
            data['walkID'] ??
            data['id'],
      );

      if (walkId.isEmpty) {
        data['walkId'] = doc.id;
      }

      return data;
    }

    return null;
  }

  // ============================================================
  // FIND BY WALK ID
  // ============================================================

  Future<HomeLiveWalk?> getByWalkId(
    String walkId,
  ) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return null;
    }

    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(collection)
            .where(
              'ownerId',
              isEqualTo: ownerId,
            )
            .limit(50)
            .get();

    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
      in snapshot.docs
    ) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      final String currentId = _string(
        data['walkId'] ??
            data['walkID'] ??
            data['id'] ??
            doc.id,
      );

      if (currentId == cleanWalkId &&
          _isLive(data)) {
        return HomeLiveWalk.fromFirestore(
          doc.id,
          data,
        );
      }
    }

    return null;
  }

  // ============================================================
  // LIVE CHECK
  // ============================================================

  bool _isLive(
    Map<String, dynamic> data,
  ) {
    final String status = _string(
      data['status'] ??
          data['walkStatus'] ??
          data['currentStatus'],
    ).toLowerCase();

    if (status.isEmpty) {
      return true;
    }

    const Set<String> inactiveStatuses = {
      'completed',
      'complete',
      'cancelled',
      'canceled',
      'ended',
      'finished',
      'rejected',
      'declined',
    };

    return !inactiveStatuses.contains(status);
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty
        ? fallback
        : result;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUid {
    return FirebaseAuth
        .instance
        .currentUser
        ?.uid;
  }
}
