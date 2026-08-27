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

  static const String collection =
      'walk_history';

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

    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(collection)
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .limit(limit)
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

        data['documentId'] = doc.id;

        result.add(data);
      }
    } catch (_) {
      return <Map<String, dynamic>>[];
    }

    result.sort(_compareDates);

    if (result.length > limit) {
      return result.take(limit).toList();
    }

    return result;
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
                    Map<String, dynamic>.from(
                  doc.data(),
                );

                data['documentId'] = doc.id;

                return data;
              },
            ).toList();

            walks.sort(_compareDates);

            return walks.take(limit).toList();
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
              isEqualTo: walkId,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      data['documentId'] = doc.id;

      return data;
    }
  } catch (_) {}

  return null;
  }
  
  // ============================================================
  // DATE SORT
  // ============================================================

  static int _compareDates(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final DateTime dateA =
        _dateFromMap(a);

    final DateTime dateB =
        _dateFromMap(b);

    return dateB.compareTo(dateA);
  }

  static DateTime _dateFromMap(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['date'] ??
            data['createdAt'] ??
            data['completedAt'] ??
            data['endedAt'] ??
            data['startTime'] ??
            data['timestamp'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final DateTime? parsed =
          DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
