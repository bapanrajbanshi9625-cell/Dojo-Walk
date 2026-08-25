import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalkService {
  ActiveWalkService._();

  static final ActiveWalkService instance =
      ActiveWalkService._();

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static const String activeWalkCollection =
      'active_walk';

  static const String historyCollection =
      'walk_history';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // ACTIVE WALK REFERENCE
  // ==========================================================

  DocumentReference<Map<String, dynamic>>
      activeWalkRef(String activeWalkId) {
    return _firestore
        .collection(activeWalkCollection)
        .doc(activeWalkId);
  }

  // ==========================================================
  // WATCH ACTIVE WALKS - OWNER
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalks({
    required String ownerId,
  }) {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection(activeWalkCollection)
        .where(
          'ownerId',
          isEqualTo: cleanOwnerId,
        )
        .where(
          'status',
          whereIn: const [
            'accepted',
            'arriving',
            'started',
            'active',
          ],
        )
        .snapshots();
  }

  // ==========================================================
  // WATCH ACTIVE WALK - SINGLE
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchActiveWalk({
    required String activeWalkId,
  }) {
    return activeWalkRef(
      activeWalkId,
    ).snapshots();
  }

  // ==========================================================
  // WATCH ACTIVE WALKS - WALKER
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchWalkerActiveWalks({
    required String walkerId,
  }) {
    final String cleanWalkerId =
        walkerId.trim();

    if (cleanWalkerId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection(activeWalkCollection)
        .where(
          'walkerId',
          isEqualTo: cleanWalkerId,
        )
        .where(
          'status',
          whereIn: const [
            'accepted',
            'arriving',
            'started',
            'active',
          ],
        )
        .snapshots();
  }

  // ==========================================================
  // CREATE ACTIVE WALK
  //
  // IMPORTANT:
  // startLocation = OWNER'S PICKUP LOCATION
  // destinationLocation = OWNER'S PICKUP LOCATION
  //
  // Walker should use this location to reach owner.
  // ==========================================================

  Future<void> createActiveWalk({
    required String walkId,
    required String ownerId,
    required String ownerName,
    required String walkerId,
    required String walkerUid,
    required String walkerName,
    String walkerPhone = '',
    required String dogName,
    required String dogBreed,
    String dogPhoto = '',
    required String address,
    required GeoPoint ownerLocation,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw ArgumentError(
        'ownerId cannot be empty.',
      );
    }

    final String cleanWalkerId =
        walkerId.trim();

    if (cleanWalkerId.isEmpty) {
      throw ArgumentError(
        'walkerId cannot be empty.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        ref =
        _firestore
            .collection(activeWalkCollection)
            .doc(cleanWalkId);

    await ref.set(
      {
        // ------------------------------------------------------
        // IDs
        // ------------------------------------------------------

        'walkId': cleanWalkId,
        'ownerId': cleanOwnerId,
        'walkerId': cleanWalkerId,
        'walkerUid':
            walkerUid.trim(),

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerName':
            ownerName.trim(),

        'address':
            address.trim(),

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerName':
            walkerName.trim(),

        'walkerPhone':
            walkerPhone.trim(),

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName':
            dogName.trim(),

        'dogBreed':
            dogBreed.trim(),

        'dogPhoto':
            dogPhoto.trim(),

        // ------------------------------------------------------
        // PICKUP LOCATION
        //
        // THIS IS OWNER'S SETUP LOCATION.
        // Walker uses this location to reach owner.
        // ------------------------------------------------------

        'startLocation':
            ownerLocation,

        'ownerLocation':
            ownerLocation,

        'destinationLocation':
            ownerLocation,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'accepted',

        // ------------------------------------------------------
        // WALK DATA
        // ------------------------------------------------------

        'steps': 0,
        'peeCount': 0,
        'poopCount': 0,

        'distanceKm': 0.0,
        'durationMinutes': 0.0,

        // ------------------------------------------------------
        // ROUTE
        //
        // Live screen does NOT need to draw this.
        // History will store it after completion.
        // ------------------------------------------------------

        'routePolyline':
            <Map<String, dynamic>>[],

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'startedAt': null,
        'completedAt': null,
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ==========================================================
  // MARK WALKER ARRIVING
  // ==========================================================

  Future<void> markArriving({
    required String activeWalkId,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'status': 'arriving',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // START WALK
  //
  // ONLY AFTER WALKER REACHES OWNER PICKUP LOCATION.
  // ==========================================================

  Future<void> startWalk({
    required String activeWalkId,
    GeoPoint? startLocation,
  }) async {
    final Map<String, dynamic> data =
        <String, dynamic>{
      'status': 'started',
      'startedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (startLocation != null) {
      // ------------------------------------------------------
      // This remains the owner's pickup location.
      // ------------------------------------------------------

      data['startLocation'] =
          startLocation;

      data['ownerLocation'] =
          startLocation;
    }

    await activeWalkRef(
      activeWalkId,
    ).update(data);
  }

  // ==========================================================
  // UPDATE LIVE WALKER LOCATION
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String activeWalkId,
    required GeoPoint location,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'walkerLocation':
          location,

      'currentLocation':
          location,

      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // UPDATE STEPS
  // ==========================================================

  Future<void> updateSteps({
    required String activeWalkId,
    required int steps,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'steps':
          steps < 0 ? 0 : steps,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // PEE + POOP
  // ==========================================================

  Future<void> updateToiletCounts({
    required String activeWalkId,
    required int peeCount,
    required int poopCount,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'peeCount':
          peeCount < 0 ? 0 : peeCount,
      'poopCount':
          poopCount < 0 ? 0 : poopCount,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // ADD PEE
  // ==========================================================

  Future<void> addPee({
    required String activeWalkId,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'peeCount':
          FieldValue.increment(1),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // ADD POOP
  // ==========================================================

  Future<void> addPoop({
    required String activeWalkId,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'poopCount':
          FieldValue.increment(1),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // ADD ROUTE POINT
  //
  // ROUTE IS STORED FOR HISTORY.
  // ==========================================================

  Future<void> addRoutePoint({
    required String activeWalkId,
    required double latitude,
    required double longitude,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'routePolyline':
          FieldValue.arrayUnion([
        <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
        },
      ]),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // SAVE COMPLETE ROUTE
  // ==========================================================

  Future<void> saveRoutePolyline({
    required String activeWalkId,
    required List<GeoPoint> points,
  }) async {
    final List<Map<String, dynamic>>
        route =
        points.map(
      (GeoPoint point) {
        return <String, dynamic>{
          'latitude':
              point.latitude,
          'longitude':
              point.longitude,
        };
      },
    ).toList();

    await activeWalkRef(
      activeWalkId,
    ).update({
      'routePolyline': route,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // COMPLETE WALK
  //
  // 1. Reads active_walk
  // 2. Creates walk_history
  // 3. Saves routePolyline
  // 4. Saves start/end/destination locations
  // 5. Marks active_walk completed
  // ==========================================================

  Future<void> completeWalk({
    required String activeWalkId,
    GeoPoint? endLocation,
    double? distanceKm,
    double? durationMinutes,
    List<GeoPoint>? routePoints,
  }) async {
    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        activeWalkRef(
      activeWalkId,
    );

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await activeRef.get();

    if (!snapshot.exists) {
      throw StateError(
        'Active walk does not exist.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // --------------------------------------------------------
    // ROUTE
    // --------------------------------------------------------

    List<Map<String, dynamic>>
        routePolyline =
        _readRoute(
      data['routePolyline'],
    );

    if (routePoints != null &&
        routePoints.isNotEmpty) {
      routePolyline =
          routePoints.map(
        (GeoPoint point) {
          return <String, dynamic>{
            'latitude':
                point.latitude,
            'longitude':
                point.longitude,
          };
        },
      ).toList();
    }

    // --------------------------------------------------------
    // START LOCATION
    //
    // OWNER PICKUP LOCATION.
    // --------------------------------------------------------

    final GeoPoint? startLocation =
        _readGeoPoint(
          data['startLocation'],
        ) ??
        _readGeoPoint(
          data['ownerLocation'],
        );

    // --------------------------------------------------------
    // DESTINATION
    //
    // For this walk, destination/pickup is owner's
    // setup location.
    // --------------------------------------------------------

    final GeoPoint? destinationLocation =
        _readGeoPoint(
          data['destinationLocation'],
        ) ??
        startLocation;

    // --------------------------------------------------------
    // END LOCATION
    // --------------------------------------------------------

    final GeoPoint? finalEndLocation =
        endLocation ??
        _readGeoPoint(
          data['endLocation'],
        ) ??
        _readGeoPoint(
          data['walkerLocation'],
        );

    // --------------------------------------------------------
    // DISTANCE
    // --------------------------------------------------------

    final double finalDistance =
        distanceKm ??
        _readDouble(
          data['distanceKm'],
        );

    // --------------------------------------------------------
    // DURATION
    // --------------------------------------------------------

    final double finalDuration =
        durationMinutes ??
        _readDouble(
          data['durationMinutes'],
        );

    // --------------------------------------------------------
    // HISTORY ID
    // --------------------------------------------------------

    final String walkId =
        _readString(
              data['walkId'],
            ).isNotEmpty
            ? _readString(
                data['walkId'],
              )
            : activeWalkId;

    final DocumentReference<
            Map<String, dynamic>>
        historyRef =
        _firestore
            .collection(
              historyCollection,
            )
            .doc(walkId);

    // --------------------------------------------------------
    // HISTORY DATA
    // --------------------------------------------------------

    final Map<String, dynamic>
        historyData =
        <String, dynamic>{
      'walkId': walkId,

      'ownerId':
          _readString(
        data['ownerId'],
      ),

      'ownerName':
          _readString(
        data['ownerName'],
      ),

      'walkerId':
          _readString(
        data['walkerId'],
      ),

      'walkerUid':
          _readString(
        data['walkerUid'],
      ),

      'walkerName':
          _readString(
        data['walkerName'],
      ),

      'walkerProfileImage':
          _readString(
        data['walkerProfileImage'],
      ),

      'walkerNote':
          _readString(
        data['walkerNote'],
      ),

      'dogName':
          _readString(
        data['dogName'],
      ),

      'dogBreed':
          _readString(
        data['dogBreed'],
      ),

      'dogPhoto':
          _readString(
        data['dogPhoto'],
      ),

      'badge':
          _readString(
        data['badge'],
      ),

      'status': 'Completed',

      'createdAt':
          data['createdAt'] ??
              DateTime.now()
                  .millisecondsSinceEpoch,

      'startedAt':
          data['startedAt'],

      'completedAt':
          FieldValue.serverTimestamp(),

      'distanceKm':
          finalDistance,

      'durationMinutes':
          finalDuration,

      'timeFormatted':
          _formatDurationMinutes(
        finalDuration,
      ),

      'peeCount':
          _readInt(
        data['peeCount'],
      ),

      'poopCount':
          _readInt(
        data['poopCount'],
      ),

      'rating':
          _readInt(
        data['rating'],
      ),

      'startLocation':
          startLocation,

      'destinationLocation':
          destinationLocation,

      'endLocation':
          finalEndLocation,

      'routeDistanceKm':
          finalDistance,

      'routeDurationMinutes':
          finalDuration,

      // ------------------------------------------------------
      // HISTORY POLYLINE
      //
      // Array of:
      // {
      //   latitude: double,
      //   longitude: double
      // }
      // ------------------------------------------------------

      'routePolyline':
          routePolyline,
    };

    // --------------------------------------------------------
    // BATCH
    // --------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      historyRef,
      historyData,
      SetOptions(
        merge: true,
      ),
    );

    batch.update(
      activeRef,
      <String, dynamic>{
        'status': 'completed',
        'endLocation':
            finalEndLocation,
        'distanceKm':
            finalDistance,
        'durationMinutes':
            finalDuration,
        'completedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ==========================================================
  // CANCEL ACTIVE WALK
  // ==========================================================

  Future<void> cancelWalk({
    required String activeWalkId,
  }) async {
    await activeWalkRef(
      activeWalkId,
    ).update({
      'status': 'cancelled',
      'completedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // GET ACTIVE WALK ONCE
  // ==========================================================

  Future<
      DocumentSnapshot<Map<String, dynamic>>>
      getActiveWalk({
    required String activeWalkId,
  }) async {
    return activeWalkRef(
      activeWalkId,
    ).get();
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _readDouble(
    dynamic value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    if (value is Map) {
      final dynamic lat =
          value['latitude'];

      final dynamic lng =
          value['longitude'];

      if (lat is num &&
          lng is num) {
        return GeoPoint(
          lat.toDouble(),
          lng.toDouble(),
        );
      }
    }

    return null;
  }

  List<Map<String, dynamic>>
      _readRoute(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
      (Map point) {
        final dynamic lat =
            point['latitude'];

        final dynamic lng =
            point['longitude'];

        if (lat is num &&
            lng is num) {
          return <String, dynamic>{
            'latitude':
                lat.toDouble(),
            'longitude':
                lng.toDouble(),
          };
        }

        return <String, dynamic>{};
      },
    )
        .where(
          (Map<String, dynamic> point) =>
              point.isNotEmpty,
        )
        .toList();
  }

  String _formatDurationMinutes(
    double minutes,
  ) {
    final int totalSeconds =
        (minutes * 60).round();

    final int hours =
        totalSeconds ~/ 3600;

    final int mins =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${mins.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${mins.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
