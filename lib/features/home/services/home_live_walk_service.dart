import 'package:cloud_firestore/cloud_firestore.dart';

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

  static const String collection =
      'active_walks';

  // ============================================================
  // LIVE WALK STREAM
  // ============================================================

  Stream<HomeLiveWalk?> stream() async* {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      yield null;
      return;
    }

    yield* _firestore
        .collection(collection)
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .snapshots()
        .map(
          (
            QuerySnapshot<Map<String, dynamic>> snapshot,
          ) {
            for (
              final QueryDocumentSnapshot<
                  Map<String, dynamic>> doc
              in snapshot.docs
            ) {
              final Map<String, dynamic> data =
                  doc.data();

              if (_isLive(data)) {
                return HomeLiveWalk.fromFirestore(
                  doc.id,
                  data,
                );
              }
            }

            return null;
          },
        );
  }

  // ============================================================
  // ONE TIME CHECK
  // ============================================================

  Future<HomeLiveWalk?> getCurrentWalk() async {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
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
            doc.data();

        if (_isLive(data)) {
          return HomeLiveWalk.fromFirestore(
            doc.id,
            data,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  // ============================================================
  // LIVE STATUS
  // ============================================================

  bool _isLive(
    Map<String, dynamic> data,
  ) {
    final dynamic isLive =
        data['isLive'] ??
            data['live'] ??
            data['liveWalk'] ??
            data['walkLive'];

    if (isLive is bool) {
      return isLive;
    }

    final String status =
        _string(
          data['status'],
        ).toLowerCase();

    const List<String> liveStatuses = <String>[
      'active',
      'live',
      'started',
      'in_progress',
      'in progress',
      'ongoing',
    ];

    return liveStatuses.contains(status);
  }

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
