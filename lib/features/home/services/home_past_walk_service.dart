import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_owner_service.dart';

class HomePastWalkService {
  HomePastWalkService._();

  static final HomePastWalkService instance =
      HomePastWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final HomeOwnerService _ownerService =
      HomeOwnerService.instance;

  static const String collection = 'walk_history';

  // ============================================================
  // GET PAST WALKS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPastWalks({
    int limit = 20,
  }) async {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final int safeLimit = limit > 0 ? limit : 20;

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(collection)
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .limit(safeLimit)
              .get();

      final List<Map<String, dynamic>> result =
          snapshot.docs.map(
        (
          QueryDocumentSnapshot<Map<String, dynamic>> doc,
        ) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data());

          data['documentId'] = doc.id;

          return data;
        },
      ).toList();

      result.sort(_compareDates);

      if (result.length > safeLimit) {
        return result.take(safeLimit).toList();
      }

      return result;
    } catch (error) {
      return <Map<String, dynamic>>[];
    }
  }

  // ============================================================
  // REALTIME STREAM
  // ============================================================

  Stream<List<Map<String, dynamic>>> stream({
    int limit = 20,
  }) async* {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      yield <Map<String, dynamic>>[];
      return;
    }

    final int safeLimit = limit > 0 ? limit : 20;

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
        final List<Map<String, dynamic>> walks =
            snapshot.docs.map(
          (
            QueryDocumentSnapshot<
                Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(doc.data());

            data['documentId'] = doc.id;

            return data;
          },
        ).toList();

        walks.sort(_compareDates);

        if (walks.length > safeLimit) {
          return walks.take(safeLimit).toList();
        }

        return walks;
      },
    );
  }

  // ============================================================
  // SINGLE WALK
  // ============================================================

  Future<Map<String, dynamic>?> getWalkById(
    String walkId,
  ) async {
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final String cleanWalkId = walkId.trim();

    if (cleanWalkId.isEmpty) {
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
              .where(
                'walkId',
                isEqualTo: cleanWalkId,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(doc.data());

      data['documentId'] = doc.id;

      return data;
    } catch (error) {
      return null;
    }
  }

  // ============================================================
  // DATE SORT
  // ============================================================

  static int _compareDates(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final DateTime dateA = _dateFromMap(a);
    final DateTime dateB = _dateFromMap(b);

    // Newest first.
    return dateB.compareTo(dateA);
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  static DateTime _dateFromMap(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['completedAt'] ??
        data['endedAt'] ??
        data['date'] ??
        data['createdAt'] ??
        data['startTime'] ??
        data['timestamp'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
