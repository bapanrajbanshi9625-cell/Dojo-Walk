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
  // Called when walker accepts an Insta Walk request.
  //
  // walkId = active_walk document ID
  // requestId = original walk_requests document ID
  // destinationLocation = owner's pickup location
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
    String requestId = '',
    String walkerUid = '',
    String walkerPhone = '',
    String dogPhoto = '',
    String walkerProfileImage = '',
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

    final String cleanOwnerName =
        ownerName.trim();

    final String cleanWalkerId =
        walkerId.trim();

    final String cleanWalkerName =
        walkerName.trim();

    final String cleanRequestId =
        requestId.trim();

    final DocumentReference<
        Map<String, dynamic>> reference =
        _activeWalks.doc(cleanWalkId);

    await reference.set(
      <String, dynamic>{
        // ------------------------------------------------------
        // BASIC
        // ------------------------------------------------------

        'walkId': cleanWalkId,

        'requestId':
            cleanRequestId,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId':
            cleanOwnerId,

        'ownerName':
            cleanOwnerName,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId':
            cleanWalkerId,

        'walkerUid':
            walkerUid.trim(),

        'walkerName':
            cleanWalkerName,

        'walkerPhone':
            walkerPhone.trim(),

        'walkerProfileImage':
            walkerProfileImage.trim(),

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
        // OWNER PICKUP
        // ------------------------------------------------------

        'address':
            address.trim(),

        'destinationLocation':
            destinationLocation,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status':
            'On that way',

        // ------------------------------------------------------
        // WALK STATS
        // ------------------------------------------------------

        'steps': 0,

        'peeCount': 0,

        'poopCount': 0,

        'distanceKm': 0.0,

        'durationMinutes': 0.0,

        'timeFormatted': '',

        'routeDistanceKm': 0.0,

        'routeDurationMinutes': 0.0,

        // ------------------------------------------------------
        // ROUTE
        // ------------------------------------------------------

        'routePolyline':
            <Map<String, dynamic>>[],

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        'walkerLocation':
            null,

        'currentLocation':
            null,

        'startLocation':
            null,

        'endLocation':
            null,

        // ------------------------------------------------------
        // TIMESTAMP
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return reference.id;
  }

  // ==========================================================
  // WATCH ONE ACTIVE WALK
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
  // WATCH OWNER ACTIVE WALKS
  //
  // Used by ActiveWalkerContainer.
  //
  // IMPORTANT:
  // This method was missing in the previous service.
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalks({
    required String ownerId,
  }) {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _activeWalks
        .where(
          'ownerId',
          isEqualTo: cleanOwnerId,
        )
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
        'status':
            'Reached',

        'reachedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ==========================================================
  // START WALK
  //
  // Walker starts actual dog walk after reaching pickup.
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
        'status':
            'Started',

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

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ==========================================================
  // UPDATE WALKER LIVE LOCATION
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
        'walkerLocation':
            location,

        'currentLocation':
            location,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ==========================================================
  // ADD ROUTE POINT
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

    // Only save route after walk has started.
    if (data['status'] != 'Started') {
      return;
    }

    final List<dynamic> existing =
        data['routePolyline'] is List
            ? List<dynamic>.from(
                data['routePolyline'],
              )
            : <dynamic>[];

    // --------------------------------------------------------
    // PREVENT DUPLICATE CONSECUTIVE POINTS
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // ADD NEW POINT
    // --------------------------------------------------------

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
        'walkerLocation':
            location,

        'currentLocation':
            location,

        'routePolyline':
            existing,

        'updatedAt':
            FieldValue.serverTimestamp(),
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
      data['steps'] =
          steps;
    }

    if (peeCount != null) {
      data['peeCount'] =
          peeCount;
    }

    if (poopCount != null) {
      data['poopCount'] =
          poopCount;
    }

    if (distanceKm != null) {
      data['distanceKm'] =
          distanceKm;

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

    data['updatedAt'] =
        FieldValue.serverTimestamp();

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

    final GeoPoint? finalDestination =
        destinationLocation ??
            _readGeoPoint(
              activeData[
                'destinationLocation'
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
    steps != 0 ? steps : _readInt(activeData['steps']);

final int finalPee =
    peeCount != 0 ? peeCount : _readInt(activeData['peeCount']);

final int finalPoop =
    poopCount != 0
        ? poopCount
        : _readInt(activeData['poopCount']);

final double finalDistance =
    distanceKm != 0.0
        ? distanceKm
        : (_readDouble(activeData['distanceKm']) ?? 0.0);

final double finalDuration =
    durationMinutes != 0.0
        ? durationMinutes
        : (_readDouble(activeData['durationMinutes']) ?? 0.0);

final String finalTime =
    timeFormatted.trim().isNotEmpty
        ? timeFormatted.trim()
        : (_readString(activeData['timeFormatted']) ?? '');

final String finalAddress =
    address.trim().isNotEmpty
        ? address.trim()
        : (_readString(activeData['address']) ?? '');

    // ========================================================
    // HISTORY
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

        'walkId':
            cleanWalkId,

        'requestId':
            _readString(
                  activeData['requestId'],
                ) ??
                '',

        'status':
            'Completed',

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId':
            ownerId.trim(),

        'ownerName':
            ownerName.trim(),

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerId':
            walkerId.trim(),

        'walkerUid':
            walkerUid.trim(),

        'walkerName':
            walkerName.trim(),

        'walkerProfileImage':
            walkerProfileImage.trim(),

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
        // OWNER PICKUP
        // ------------------------------------------------------

        'address':
            finalAddress,

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

        'steps':
            finalSteps,

        'peeCount':
            finalPee,

        'poopCount':
            finalPoop,

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

        'badge':
            badge.trim(),

        'walkerNote':
            walkerNote.trim(),

        'rating':
            0,

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
        'status':
            'Completed',

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

        'steps':
            finalSteps,

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

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ==========================================================
  // CANCEL ACTIVE WALK
  //
  // Used when walk is cancelled from another part of app.
  // ==========================================================

  Future<void> cancelActiveWalk({
    required String walkId,
    String cancelledBy = 'owner',
    String cancelledByUid = '',
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
    }

    await _activeWalks
        .doc(cleanWalkId)
        .set(
      <String, dynamic>{
        'status':
            'cancelled',

        'cancelledBy':
            cancelledBy.trim(),

        'cancelledByUid':
            cancelledByUid.trim(),

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
  // GET ACTIVE WALK ONCE
  // ==========================================================

  Future<
      DocumentSnapshot<
          Map<String, dynamic>>> getActiveWalk(
    String walkId,
  ) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    return _activeWalks
        .doc(cleanWalkId)
        .get();
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

    if (value is Map) {
      final dynamic latitude =
          value['latitude'] ??
              value['lat'];

      final dynamic longitude =
          value['longitude'] ??
              value['lng'] ??
              value['lon'];

      if (latitude is num &&
          longitude is num) {
        return GeoPoint(
          latitude.toDouble(),
          longitude.toDouble(),
        );
      }
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
