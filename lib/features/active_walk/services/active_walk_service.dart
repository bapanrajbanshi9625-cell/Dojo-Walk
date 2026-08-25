import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalkService {
  ActiveWalkService._();

  static final ActiveWalkService instance =
      ActiveWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // COLLECTION
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  // ==========================================================
  // CREATE ACTIVE WALK
  //
  // Called after Walker accepts the request.
  //
  // destinationLocation = OWNER PICKUP LOCATION
  // ==========================================================

  Future<String> createActiveWalk({
    required String walkId,
    required String ownerId,
    required String ownerName,
    required String walkerId,
    required String walkerName,
    required String dogName,
    required String dogBreed,
    required String address,
    required GeoPoint destinationLocation,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>> reference =
        _activeWalks.doc(cleanWalkId);

    await reference.set(
      <String, dynamic>{
        'walkId': cleanWalkId,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId.trim(),
        'ownerName': ownerName.trim(),

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId': walkerId.trim(),
        'walkerName': walkerName.trim(),

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName.trim(),
        'dogBreed': dogBreed.trim(),

        // ------------------------------------------------------
        // PICKUP
        // ------------------------------------------------------

        'address': address.trim(),

        // IMPORTANT:
        // This is OWNER'S setup pickup location.
        'destinationLocation':
            destinationLocation,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'On that way',

        // ------------------------------------------------------
        // CREATED
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return reference.id;
  }

  // ==========================================================
  // WATCH ACTIVE WALK
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchActiveWalk(
    String walkId,
  ) {
    return _activeWalks
        .doc(walkId.trim())
        .snapshots();
  }

  // ==========================================================
  // WALKER REACHED PICKUP
  //
  // This does NOT start the walk.
  // ==========================================================

  Future<void> markReached({
    required String walkId,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    await _activeWalks
        .doc(cleanWalkId)
        .update(
      <String, dynamic>{
        'status': 'Reached',

        'reachedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ==========================================================
  // START WALK
  //
  // ONLY AFTER WALKER HAS REACHED PICKUP.
  // ==========================================================

  Future<void> startWalk({
    required String walkId,
    GeoPoint? startLocation,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    final Map<String, dynamic> data =
        <String, dynamic>{
      'status': 'Started',

      'startedAt':
          FieldValue.serverTimestamp(),

      'routePolyline':
          <Map<String, dynamic>>[],
    };

    if (startLocation != null) {
      data['startLocation'] =
          startLocation;

      // Initial live position.
      data['walkerLocation'] =
          startLocation;
    }

    await _activeWalks
        .doc(cleanWalkId)
        .update(data);
  }

  // ==========================================================
  // UPDATE WALKER LIVE LOCATION
  //
  // Only use while status == Started.
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String walkId,
    required GeoPoint location,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    await _activeWalks
        .doc(cleanWalkId)
        .update(
      <String, dynamic>{
        'walkerLocation': location,
        'currentLocation': location,
      },
    );
  }

  // ==========================================================
  // UPDATE WALK STATS
  // ==========================================================

  Future<void> updateWalkStats({
    required String walkId,
    int? steps,
    int? peeCount,
    int? poopCount,
    double? distanceKm,
  }) async {
    final Map<String, dynamic> data =
        <String, dynamic>{};

    if (steps != null) {
      data['steps'] = steps;
    }

    if (peeCount != null) {
      data['peeCount'] = peeCount;
    }

    if (poopCount != null) {
      data['poopCount'] = poopCount;
    }

    if (distanceKm != null) {
      data['distanceKm'] = distanceKm;
    }

    if (data.isEmpty) {
      return;
    }

    await _activeWalks
        .doc(walkId.trim())
        .update(data);
  }

  // ==========================================================
  // ADD ROUTE POINT
  //
  // Polyline is stored as latitude/longitude maps.
  // This is for HISTORY.
  // ==========================================================

  Future<void> addRoutePoint({
    required String walkId,
    required GeoPoint location,
  }) async {
    await _activeWalks
        .doc(walkId.trim())
        .update(
      <String, dynamic>{
        'routePolyline':
            FieldValue.arrayUnion(
          <Map<String, dynamic>>[
            <String, dynamic>{
              'latitude':
                  location.latitude,
              'longitude':
                  location.longitude,
            },
          ],
        ),
      },
    );
  }

  // ==========================================================
  // END WALK
  //
  // Saves final data into walk_history.
  // ==========================================================

  Future<void> endWalk({
    required String walkId,
    required String ownerId,
    required String ownerName,
    required String walkerId,
    required String walkerName,
    required String dogName,
    required String dogBreed,
    GeoPoint? startLocation,
    GeoPoint? endLocation,
    GeoPoint? destinationLocation,
    String dogPhoto = '',
    String walkerProfileImage = '',
    String walkerUid = '',
    String address = '',
    int steps = 0,
    int peeCount = 0,
    int poopCount = 0,
    double distanceKm = 0,
    double durationMinutes = 0,
    String timeFormatted = '',
    String badge = '',
    String walkerNote = '',
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>> activeReference =
        _activeWalks.doc(cleanWalkId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await activeReference.get();

    final Map<String, dynamic> activeData =
        snapshot.data() ??
            <String, dynamic>{};

    // ----------------------------------------------------------
    // Get route from active_walk.
    // ----------------------------------------------------------

    final dynamic savedPolyline =
        activeData['routePolyline'];

    final List<dynamic> routePolyline =
        savedPolyline is List
            ? List<dynamic>.from(
                savedPolyline,
              )
            : <dynamic>[];

    final GeoPoint? finalStartLocation =
        startLocation ??
            _readGeoPoint(
              activeData['startLocation'],
            );

    final GeoPoint? finalEndLocation =
        endLocation ??
            _readGeoPoint(
              activeData['walkerLocation'],
            ) ??
            _readGeoPoint(
              activeData['currentLocation'],
            );

    final GeoPoint? finalDestination =
        destinationLocation ??
            _readGeoPoint(
              activeData['destinationLocation'],
            );

    final DocumentReference<
        Map<String, dynamic>> historyReference =
        _firestore
            .collection('walk_history')
            .doc(cleanWalkId);

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // HISTORY
    // ----------------------------------------------------------

    batch.set(
      historyReference,
      <String, dynamic>{
        'walkId': cleanWalkId,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId.trim(),
        'ownerName': ownerName.trim(),

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId': walkerId.trim(),
        'walkerName': walkerName.trim(),
        'walkerUid': walkerUid.trim(),
        'walkerProfileImage':
            walkerProfileImage.trim(),

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName.trim(),
        'dogBreed': dogBreed.trim(),
        'dogPhoto': dogPhoto.trim(),

        // ------------------------------------------------------
        // PICKUP / DESTINATION
        // ------------------------------------------------------

        'address': address.trim(),
        'destinationLocation':
            finalDestination,

        // ------------------------------------------------------
        // ROUTE
        // ------------------------------------------------------

        'startLocation':
            finalStartLocation,

        'endLocation':
            finalEndLocation,

        'routePolyline':
            routePolyline,

        // ------------------------------------------------------
        // STATS
        // ------------------------------------------------------

        'steps': steps,
        'peeCount': peeCount,
        'poopCount': poopCount,

        'distanceKm': distanceKm,
        'durationMinutes':
            durationMinutes,

        'timeFormatted':
            timeFormatted,

        // ------------------------------------------------------
        // OTHER
        // ------------------------------------------------------

        'badge': badge,
        'walkerNote':
            walkerNote.trim(),

        'rating': 0,

        'status': 'Completed',

        'startedAt':
            activeData['startedAt'],

        'completedAt':
            FieldValue.serverTimestamp(),

        'createdAt':
            DateTime.now()
                .millisecondsSinceEpoch,
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // ACTIVE WALK COMPLETED
    // ----------------------------------------------------------

    batch.update(
      activeReference,
      <String, dynamic>{
        'status': 'Completed',

        'completedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ==========================================================
  // DELETE ACTIVE WALK
  // ==========================================================

  Future<void> deleteActiveWalk(
    String walkId,
  ) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
    }

    await _activeWalks
        .doc(cleanWalkId)
        .delete();
  }

  // ==========================================================
  // GEOPOINT HELPER
  // ==========================================================

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }
}
