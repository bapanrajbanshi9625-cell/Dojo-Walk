import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalkService {
  ActiveWalkService._();

  static final ActiveWalkService instance =
      ActiveWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>>
      get _history =>
          _firestore.collection('walk_history');

  // ==========================================================
  // CREATE ACTIVE WALK
  //
  // Walker accepts request.
  //
  // destinationLocation = OWNER'S PICKUP LOCATION
  // status = On that way
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
    String walkerUid = '',
    String walkerPhone = '',
    String dogPhoto = '',
    String walkerProfileImage = '',
  }) async {
    final String cleanWalkId = walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        reference =
        _activeWalks.doc(cleanWalkId);

    await reference.set(
      <String, dynamic>{
        // ------------------------------------------------------
        // BASIC
        // ------------------------------------------------------

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
        'walkerUid': walkerUid.trim(),
        'walkerName': walkerName.trim(),
        'walkerPhone': walkerPhone.trim(),
        'walkerProfileImage':
            walkerProfileImage.trim(),

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName.trim(),
        'dogBreed': dogBreed.trim(),
        'dogPhoto': dogPhoto.trim(),

        // ------------------------------------------------------
        // OWNER PICKUP LOCATION
        // ------------------------------------------------------

        'address': address.trim(),

        // IMPORTANT:
        // Owner द्वारा setup की गई pickup location.
        // Walker इसी location पर जाएगा.
        'destinationLocation':
            destinationLocation,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'On that way',

        // ------------------------------------------------------
        // INITIAL WALK DATA
        // ------------------------------------------------------

        'steps': 0,
        'peeCount': 0,
        'poopCount': 0,
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'timeFormatted': '',

        'routeDistanceKm': 0.0,
        'routeDurationMinutes': 0.0,

        'routePolyline':
            <Map<String, dynamic>>[],

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
    final String cleanWalkId =
        walkId.trim();

    return _activeWalks
        .doc(cleanWalkId)
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
  // Only after walker reaches owner's pickup location.
  // ==========================================================

  Future<void> startWalk({
    required String walkId,
    required GeoPoint startLocation,
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
        'status': 'Started',

        'startedAt':
            FieldValue.serverTimestamp(),

        'startLocation':
            startLocation,

        'walkerLocation':
            startLocation,

        'currentLocation':
            startLocation,

        'routePolyline':
            <Map<String, dynamic>>[
          <String, dynamic>{
            'latitude':
                startLocation.latitude,
            'longitude':
                startLocation.longitude,
          },
        ],

        'steps': 0,
        'peeCount': 0,
        'poopCount': 0,
        'distanceKm': 0.0,
        'durationMinutes': 0.0,
        'timeFormatted': '',
        'routeDistanceKm': 0.0,
        'routeDurationMinutes': 0.0,
      },
    );
  }

  // ==========================================================
  // UPDATE WALKER LIVE LOCATION
  //
  // Only while status == Started.
  // ==========================================================

  Future<void> updateWalkerLocation({
    required String walkId,
    required GeoPoint location,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
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
  // ADD ROUTE POINT
  //
  // routePolyline:
  //
  // [
  //   {
  //     latitude: 28.123,
  //     longitude: 77.123
  //   }
  // ]
  // ==========================================================

  Future<void> addRoutePoint({
    required String walkId,
    required GeoPoint location,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
    }

    final DocumentReference<
        Map<String, dynamic>> reference =
        _activeWalks.doc(cleanWalkId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await reference.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // Only save route when actual walk has started.
    if (data['status'] != 'Started') {
      return;
    }

    final List<dynamic> existing =
        data['routePolyline'] is List
            ? List<dynamic>.from(
                data['routePolyline'],
              )
            : <dynamic>[];

    // ----------------------------------------------------------
    // Avoid duplicate consecutive points.
    // ----------------------------------------------------------

    if (existing.isNotEmpty) {
      final dynamic last =
          existing.last;

      if (last is Map) {
        final double? lastLat =
            _readDouble(
          last['latitude'],
        );

        final double? lastLng =
            _readDouble(
          last['longitude'],
        );

        if (lastLat != null &&
            lastLng != null) {
          final double latDifference =
              (lastLat -
                      location.latitude)
                  .abs();

          final double lngDifference =
              (lastLng -
                      location.longitude)
                  .abs();

          if (latDifference < 0.00001 &&
              lngDifference < 0.00001) {
            return;
          }
        }
      }
    }

    existing.add(
      <String, dynamic>{
        'latitude':
            location.latitude,
        'longitude':
            location.longitude,
      },
    );

    await reference.update(
      <String, dynamic>{
        'walkerLocation': location,
        'currentLocation': location,
        'routePolyline': existing,
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
    double? durationMinutes,
    String? timeFormatted,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
    }

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
      data['routeDistanceKm'] =
          distanceKm;
    }

    if (durationMinutes != null) {
      data['durationMinutes'] =
          durationMinutes;

      data['routeDurationMinutes'] =
          durationMinutes;
    }

    if (timeFormatted != null) {
      data['timeFormatted'] =
          timeFormatted;
    }

    if (data.isEmpty) {
      return;
    }

    await _activeWalks
        .doc(cleanWalkId)
        .update(data);
  }

  // ==========================================================
  // END WALK
  //
  // 1. Read active_walk
  // 2. Save walk_history
  // 3. Mark active_walk Completed
  //
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

    double distanceKm = 0.0,
    double durationMinutes = 0.0,

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

    if (!snapshot.exists) {
      throw StateError(
        'Active walk does not exist.',
      );
    }

    final Map<String, dynamic> activeData =
        snapshot.data() ??
            <String, dynamic>{};

    // ========================================================
    // LOCATIONS
    // ========================================================

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

    // IMPORTANT:
    // Destination remains owner's pickup location.
    final GeoPoint? finalDestination =
        destinationLocation ??
            _readGeoPoint(
              activeData[
                'destinationLocation',
              ],
            );

    // ========================================================
    // ROUTE
    // ========================================================

    final List<dynamic> routePolyline =
        activeData['routePolyline'] is List
            ? List<dynamic>.from(
                activeData['routePolyline'],
              )
            : <dynamic>[];

    // ========================================================
    // STATS
    // ========================================================

    final int finalSteps =
        steps != 0
            ? steps
            : _readInt(
                activeData['steps'],
              );

    final int finalPee =
        peeCount != 0
            ? peeCount
            : _readInt(
                activeData['peeCount'],
              );

    final int finalPoop =
        poopCount != 0
            ? poopCount
            : _readInt(
                activeData['poopCount'],
              );

    final double finalDistance =
        distanceKm != 0.0
            ? distanceKm
            : _readDouble(
                  activeData['distanceKm'],
                ) ??
                0.0;

    final double finalDuration =
        durationMinutes != 0.0
            ? durationMinutes
            : _readDouble(
                  activeData[
                    'durationMinutes',
                  ],
                ) ??
                0.0;

    final String finalTime =
        timeFormatted.trim().isNotEmpty
            ? timeFormatted.trim()
            : _readString(
                  activeData[
                    'timeFormatted',
                  ],
                ) ??
                '';

    final String finalAddress =
        address.trim().isNotEmpty
            ? address.trim()
            : _readString(
                  activeData['address'],
                ) ??
                '';

    // ========================================================
    // HISTORY REFERENCE
    // ========================================================

    final DocumentReference<
        Map<String, dynamic>> historyReference =
        _history.doc(cleanWalkId);

    final WriteBatch batch =
        _firestore.batch();

    // ========================================================
    // SAVE WALK HISTORY
    // ========================================================

    batch.set(
      historyReference,
      <String, dynamic>{
        // ------------------------------------------------------
        // BASIC
        // ------------------------------------------------------

        'walkId': cleanWalkId,
        'status': 'Completed',

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId.trim(),
        'ownerName': ownerName.trim(),

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId': walkerId.trim(),
        'walkerUid': walkerUid.trim(),
        'walkerName': walkerName.trim(),

        'walkerProfileImage':
            walkerProfileImage.trim(),

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName.trim(),
        'dogBreed': dogBreed.trim(),
        'dogPhoto': dogPhoto.trim(),

        // ------------------------------------------------------
        // OWNER PICKUP
        // ------------------------------------------------------

        'address': finalAddress,

        'destinationLocation':
            finalDestination,

        // ------------------------------------------------------
        // WALK ROUTE
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

        'steps': finalSteps,
        'peeCount': finalPee,
        'poopCount': finalPoop,

        'distanceKm':
            finalDistance,

        'durationMinutes':
            finalDuration,

        'timeFormatted':
            finalTime,

        // ------------------------------------------------------
        // ROUTE SUMMARY
        // ------------------------------------------------------

        'routeDistanceKm':
            finalDistance,

        'routeDurationMinutes':
            finalDuration,

        // ------------------------------------------------------
        // OTHER
        // ------------------------------------------------------

        'badge': badge.trim(),

        'walkerNote':
            walkerNote.trim(),

        'rating': 0,

        // ------------------------------------------------------
        // TIME
        // ------------------------------------------------------

        'startedAt':
            activeData['startedAt'],

        'completedAt':
            FieldValue.serverTimestamp(),

        'createdAt':
            DateTime.now()
                .millisecondsSinceEpoch,

        'date':
            _formatDate(
          DateTime.now(),
        ),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // MARK ACTIVE WALK COMPLETED
    // ========================================================

    batch.update(
      activeReference,
      <String, dynamic>{
        'status': 'Completed',

        'endLocation':
            finalEndLocation,

        'completedAt':
            FieldValue.serverTimestamp(),

        'distanceKm':
            finalDistance,

        'durationMinutes':
            finalDuration,

        'timeFormatted':
            finalTime,

        'steps': finalSteps,

        'peeCount':
            finalPee,

        'poopCount':
            finalPoop,

        'routeDistanceKm':
            finalDistance,

        'routeDurationMinutes':
            finalDuration,

        'routePolyline':
            routePolyline,
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
  // HELPERS
  // ==========================================================

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  String? _readString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
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

  double? _readDouble(
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
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
