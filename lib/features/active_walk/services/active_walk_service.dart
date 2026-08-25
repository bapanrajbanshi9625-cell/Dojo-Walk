import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class ActiveWalkService {
  ActiveWalkService._internal();

  static final ActiveWalkService instance =
      ActiveWalkService._internal();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static const String activeWalkCollection =
      'active_walk';

  static const String historyCollection =
      'walk_history';

  // ==========================================================
  // WATCH ACTIVE WALKS
  //
  // Owner app:
  // ownerId -> active_walk
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

    return _firestore
        .collection(activeWalkCollection)
        .where(
          'ownerId',
          isEqualTo: cleanOwnerId,
        )
        .where(
          'status',
          whereIn: const [
            'Accepted',
            'Reached',
            'Started',
            'Live',
            'Active',
          ],
        )
        .snapshots();
  }

  // ==========================================================
  // WATCH SINGLE ACTIVE WALK
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchActiveWalk({
    required String activeWalkId,
  }) {
    return _firestore
        .collection(activeWalkCollection)
        .doc(activeWalkId.trim())
        .snapshots();
  }

  // ==========================================================
  // GET ACTIVE WALK
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      getActiveWalk({
    required String activeWalkId,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> document =
          await _firestore
              .collection(activeWalkCollection)
              .doc(id)
              .get();

      if (!document.exists) {
        return null;
      }

      return document;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // CREATE ACTIVE WALK
  //
  // Called when Walker accepts Owner's request.
  //
  // IMPORTANT:
  // destinationLocation = Owner pickup location
  // ==========================================================

  Future<String?> createActiveWalk({
    required String walkId,
    required String ownerId,
    required String ownerName,
    required String walkerId,
    required String walkerUid,
    required String walkerName,
    String walkerPhone = '',
    String dogName = '',
    String dogBreed = '',
    String dogPhoto = '',
    String address = '',
    GeoPoint? destinationLocation,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return null;
    }

    if (ownerId.trim().isEmpty ||
        walkerId.trim().isEmpty ||
        walkerUid.trim().isEmpty) {
      return null;
    }

    final DocumentReference<
        Map<String, dynamic>> reference =
        _firestore
            .collection(activeWalkCollection)
            .doc(cleanWalkId);

    final Map<String, dynamic> data =
        <String, dynamic>{
      'walkId': cleanWalkId,

      'ownerId':
          ownerId.trim(),

      'ownerName':
          ownerName.trim(),

      'walkerId':
          walkerId.trim(),

      'walkerUid':
          walkerUid.trim(),

      'walkerName':
          walkerName.trim(),

      'walkerPhone':
          walkerPhone.trim(),

      'dogName':
          dogName.trim(),

      'dogBreed':
          dogBreed.trim(),

      'dogPhoto':
          dogPhoto.trim(),

      // Owner's configured pickup address.
      'address':
          address.trim(),

      'destinationAddress':
          address.trim(),

      // Owner pickup location.
      if (destinationLocation != null)
        'destinationLocation':
            destinationLocation,

      if (destinationLocation != null)
        'ownerLocation':
            destinationLocation,

      'status':
          'Accepted',

      'createdAt':
          FieldValue.serverTimestamp(),

      'startedAt':
          null,

      'endedAt':
          null,

      'currentLocation':
          null,

      'walkerLocation':
          null,

      'steps':
          0,

      'peeCount':
          0,

      'poopCount':
          0,

      'distance':
          '0.0 km',

      'distanceKm':
          0.0,

      'durationMinutes':
          0.0,

      // Live route points.
      'routePoints':
          <Map<String, dynamic>>[],
    };

    try {
      await reference.set(
        data,
        SetOptions(
          merge: true,
        ),
      );

      return reference.id;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // MARK REACHED
  //
  // Walker has reached Owner pickup location.
  // ==========================================================

  Future<bool> markReached({
    required String activeWalkId,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      await _firestore
          .collection(activeWalkCollection)
          .doc(id)
          .update({
        'status':
            'Reached',
        'reachedAt':
            FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // START WALK
  //
  // Called AFTER Walker reaches pickup.
  // ==========================================================

  Future<bool> startWalk({
    required String activeWalkId,
    GeoPoint? startLocation,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    final GeoPoint? location =
        startLocation ??
            await _getCurrentGeoPoint();

    final Map<String, dynamic>
        update =
        <String, dynamic>{
      'status':
          'Started',

      'startedAt':
          FieldValue.serverTimestamp(),

      'steps':
          0,

      'peeCount':
          0,

      'poopCount':
          0,

      'distanceKm':
          0.0,

      'distance':
          '0.0 km',

      'durationMinutes':
          0.0,

      'routePoints':
          <Map<String, dynamic>>[],
    };

    if (location != null) {
      update['startLocation'] =
          location;

      update['currentLocation'] =
          location;

      update['walkerLocation'] =
          location;

      update['routePoints'] = [
        <String, dynamic>{
          'latitude':
              location.latitude,
          'longitude':
              location.longitude,
        },
      ];
    }

    try {
      await _firestore
          .collection(activeWalkCollection)
          .doc(id)
          .update(update);

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // START LOCATION TRACKING
  //
  // Returns a subscription.
  //
  // Walker app should keep this subscription while walk
  // is active.
  // ==========================================================

  StreamSubscription<Position>?
      startLocationTracking({
    required String activeWalkId,
  }) {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return null;
    }

    const LocationSettings
        settings =
        LocationSettings(
      accuracy:
          LocationAccuracy.high,
      distanceFilter: 5,
    );

    try {
      return Geolocator
          .getPositionStream(
        locationSettings:
            settings,
      )
          .listen(
        (Position position) {
          updateWalkerLocation(
            activeWalkId: id,
            latitude:
                position.latitude,
            longitude:
                position.longitude,
          );
        },
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // UPDATE WALKER LOCATION
  //
  // Adds a point to routePoints.
  // ==========================================================

  Future<bool> updateWalkerLocation({
    required String activeWalkId,
    required double latitude,
    required double longitude,
    int? steps,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    final DocumentReference<
        Map<String, dynamic>> reference =
        _firestore
            .collection(activeWalkCollection)
            .doc(id);

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await reference.get();

      if (!snapshot.exists) {
        return false;
      }

      final Map<String, dynamic>
          data =
          snapshot.data() ??
              <String, dynamic>{};

      final String status =
          data['status']
                  ?.toString()
                  .trim() ??
              '';

      if (status != 'Started' &&
          status != 'Live' &&
          status != 'Active') {
        return false;
      }

      final List<Map<String, dynamic>>
          points =
          _readRoutePoints(
        data['routePoints'],
      );

      final GeoPoint? previous =
          _readGeoPoint(
        data['currentLocation'],
      );

      double totalDistance =
          _readDouble(
        data['distanceKm'],
      );

      if (previous != null) {
        totalDistance +=
            _distanceKm(
          previous.latitude,
          previous.longitude,
          latitude,
          longitude,
        );
      }

      final Map<String, dynamic>
          newPoint =
          <String, dynamic>{
        'latitude':
            latitude,
        'longitude':
            longitude,
      };

      // Avoid saving duplicate points.
      if (!_isSamePoint(
        points.isNotEmpty
            ? points.last
            : null,
        latitude,
        longitude,
      )) {
        points.add(
          newPoint,
        );
      }

      final double
          durationMinutes =
          _calculateDurationMinutes(
        data['startedAt'],
      );

      final Map<String, dynamic>
          update =
          <String, dynamic>{
        'status':
            'Live',

        'currentLocation':
            GeoPoint(
          latitude,
          longitude,
        ),

        'walkerLocation':
            GeoPoint(
          latitude,
          longitude,
        ),

        'distanceKm':
            totalDistance,

        'distance':
            '${totalDistance.toStringAsFixed(2)} km',

        'durationMinutes':
            durationMinutes,

        'routePoints':
            points,

        if (steps != null)
          'steps': steps,
      };

      await reference.update(
        update,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // UPDATE STEPS
  // ==========================================================

  Future<bool> updateSteps({
    required String activeWalkId,
    required int steps,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      await _firestore
          .collection(activeWalkCollection)
          .doc(id)
          .update({
        'steps':
            math.max(0, steps),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // UPDATE PEE
  // ==========================================================

  Future<bool> updatePeeCount({
    required String activeWalkId,
    required int count,
  }) async {
    return _updateCount(
      activeWalkId:
          activeWalkId,
      field:
          'peeCount',
      count:
          count,
    );
  }

  // ==========================================================
  // UPDATE POOP
  // ==========================================================

  Future<bool> updatePoopCount({
    required String activeWalkId,
    required int count,
  }) async {
    return _updateCount(
      activeWalkId:
          activeWalkId,
      field:
          'poopCount',
      count:
          count,
    );
  }

  Future<bool> _updateCount({
    required String activeWalkId,
    required String field,
    required int count,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      await _firestore
          .collection(activeWalkCollection)
          .doc(id)
          .update({
        field:
            math.max(0, count),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // END WALK
  //
  // IMPORTANT:
  // active_walk routePoints
  //          ↓
  // walk_history routePolyline
  // ==========================================================

  Future<bool> endWalk({
    required String activeWalkId,
    String walkerNote = '',
    int rating = 0,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> activeReference =
          _firestore
              .collection(activeWalkCollection)
              .doc(id);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await activeReference.get();

      if (!snapshot.exists) {
        return false;
      }

      final Map<String, dynamic>
          active =
          snapshot.data() ??
              <String, dynamic>{};

      final List<Map<String, dynamic>>
          routePoints =
          _readRoutePoints(
        active['routePoints'],
      );

      final GeoPoint? startLocation =
          _readGeoPoint(
        active['startLocation'],
      );

      final GeoPoint? destinationLocation =
          _readGeoPoint(
        active['destinationLocation'],
      );

      final GeoPoint? endLocation =
          _readGeoPoint(
            active['currentLocation'],
          ) ??
          _readGeoPoint(
            active['walkerLocation'],
          );

      final double routeDistance =
          _calculateRouteDistance(
        routePoints,
      );

      final double durationMinutes =
          _calculateDurationMinutes(
        active['startedAt'],
      );

      final Timestamp completedAt =
          Timestamp.now();

      final String historyId =
          _readString(
                active['walkId'],
              ) ??
              id;

      final DocumentReference<
          Map<String, dynamic>> historyReference =
          _firestore
              .collection(historyCollection)
              .doc(historyId);

      final List<Map<String, dynamic>>
          cleanPolyline =
          routePoints
              .map(
                (
                  Map<String, dynamic>
                      point,
                ) =>
                    <String, dynamic>{
                  'latitude':
                      _readDouble(
                    point['latitude'],
                  ),
                  'longitude':
                      _readDouble(
                    point['longitude'],
                  ),
                },
              )
              .toList();

      // ------------------------------------------------------
      // HISTORY
      // ------------------------------------------------------

      final Map<String, dynamic>
          historyData =
          <String, dynamic>{
        'walkId':
            historyId,

        'ownerId':
            _readString(
                  active['ownerId'],
                ) ??
                '',

        'ownerName':
            _readString(
                  active['ownerName'],
                ) ??
                '',

        'walkerId':
            _readString(
                  active['walkerId'],
                ) ??
                '',

        'walkerUid':
            _readString(
                  active['walkerUid'],
                ) ??
                '',

        'walkerName':
            _readString(
                  active['walkerName'],
                ) ??
                '',

        'walkerProfileImage':
            _readString(
                  active[
                      'walkerProfileImage'],
                ) ??
                '',

        'walkerNote':
            walkerNote.trim(),

        'dogName':
            _readString(
                  active['dogName'],
                ) ??
                '',

        'dogBreed':
            _readString(
                  active['dogBreed'],
                ) ??
                '',

        'dogPhoto':
            _readString(
                  active['dogPhoto'],
                ) ??
                '',

        'badge':
            _readString(
                  active['badge'],
                ) ??
                '',

        'status':
            'Completed',

        'createdAt':
            DateTime.now()
                .millisecondsSinceEpoch,

        'startedAt':
            active['startedAt'],

        'completedAt':
            completedAt,

        'date':
            _formatDate(
          DateTime.now(),
        ),

        'timeFormatted':
            _formatTime(
          DateTime.now(),
        ),

        'distanceKm':
            routeDistance,

        'routeDistanceKm':
            routeDistance,

        'durationMinutes':
            durationMinutes,

        'routeDurationMinutes':
            durationMinutes,

        'peeCount':
            _readInt(
          active['peeCount'],
        ),

        'poopCount':
            _readInt(
          active['poopCount'],
        ),

        'rating':
            math.max(
          0,
          rating,
        ),

        'routePolyline':
            cleanPolyline,

        if (startLocation != null)
          'startLocation':
              startLocation,

        if (endLocation != null)
          'endLocation':
              endLocation,

        if (destinationLocation != null)
          'destinationLocation':
              destinationLocation,
      };

      // ------------------------------------------------------
      // BATCH
      // ------------------------------------------------------

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        historyReference,
        historyData,
        SetOptions(
          merge: true,
        ),
      );

      batch.update(
        activeReference,
        <String, dynamic>{
          'status':
              'Completed',

          'endedAt':
              FieldValue.serverTimestamp(),

          'completedAt':
              FieldValue.serverTimestamp(),

          'distanceKm':
              routeDistance,

          'distance':
              '${routeDistance.toStringAsFixed(2)} km',

          'durationMinutes':
              durationMinutes,

          'routeDistanceKm':
              routeDistance,

          'routeDurationMinutes':
              durationMinutes,

          'routePolyline':
              cleanPolyline,

          if (endLocation != null)
            'endLocation':
                endLocation,
        },
      );

      await batch.commit();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // DELETE ACTIVE WALK
  //
  // Use only for cancelled/invalid active walks.
  // ==========================================================

  Future<bool> deleteActiveWalk({
    required String activeWalkId,
  }) async {
    final String id =
        activeWalkId.trim();

    if (id.isEmpty) {
      return false;
    }

    try {
      await _firestore
          .collection(activeWalkCollection)
          .doc(id)
          .delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // LOCATION PERMISSION
  // ==========================================================

  Future<bool>
      ensureLocationPermission() async {
    try {
      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission =
          await Geolocator
              .checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // CURRENT LOCATION
  // ==========================================================

  Future<GeoPoint?>
      _getCurrentGeoPoint() async {
    final bool allowed =
        await ensureLocationPermission();

    if (!allowed) {
      return null;
    }

    try {
      final Position position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      return GeoPoint(
        position.latitude,
        position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // ROUTE DISTANCE
  // ==========================================================

  double _calculateRouteDistance(
    List<Map<String, dynamic>>
        points,
  ) {
    if (points.length < 2) {
      return 0.0;
    }

    double total = 0.0;

    for (int i = 1;
        i < points.length;
        i++) {
      final double lat1 =
          _readDouble(
        points[i - 1]['latitude'],
      );

      final double lng1 =
          _readDouble(
        points[i - 1]['longitude'],
      );

      final double lat2 =
          _readDouble(
        points[i]['latitude'],
      );

      final double lng2 =
          _readDouble(
        points[i]['longitude'],
      );

      total +=
          _distanceKm(
        lat1,
        lng1,
        lat2,
        lng2,
      );
    }

    return total;
  }

  // ==========================================================
  // HAVERSINE DISTANCE
  // ==========================================================

  double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm =
        6371.0;

    final double dLat =
        _toRadians(
      lat2 - lat1,
    );

    final double dLng =
        _toRadians(
      lng2 - lng1,
    );

    final double a =
        math.pow(
              math.sin(
                dLat / 2,
              ),
              2,
            ) +
            math.cos(
              _toRadians(lat1),
            ) *
                math.cos(
                  _toRadians(lat2),
                ) *
                math.pow(
                  math.sin(
                    dLng / 2,
                  ),
                  2,
                );

    final double c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(
                1 - a,
              ),
            );

    return earthRadiusKm * c;
  }

  double _toRadians(
    double degree,
  ) {
    return degree *
        math.pi /
        180.0;
  }

  // ==========================================================
  // DURATION
  // ==========================================================

  double _calculateDurationMinutes(
    dynamic startedAt,
  ) {
    final DateTime? start =
        _readDate(
      startedAt,
    );

    if (start == null) {
      return 0.0;
    }

    final Duration difference =
        DateTime.now().difference(
      start,
    );

    return difference
            .inSeconds /
        60.0;
  }

  // ==========================================================
  // ROUTE POINT READER
  // ==========================================================

  List<Map<String, dynamic>>
      _readRoutePoints(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map point) =>
              Map<String, dynamic>.from(
            point,
          ),
        )
        .where(
          (Map<String, dynamic> point) =>
              point['latitude'] != null &&
              point['longitude'] != null,
        )
        .toList();
  }

  // ==========================================================
  // DUPLICATE POINT CHECK
  // ==========================================================

  bool _isSamePoint(
    Map<String, dynamic>? previous,
    double latitude,
    double longitude,
  ) {
    if (previous == null) {
      return false;
    }

    final double oldLat =
        _readDouble(
      previous['latitude'],
    );

    final double oldLng =
        _readDouble(
      previous['longitude'],
    );

    return (oldLat - latitude).abs() <
            0.00001 &&
        (oldLng - longitude).abs() <
            0.00001;
  }

  // ==========================================================
  // GEOPOINT
  // ==========================================================

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  // ==========================================================
  // STRING
  // ==========================================================

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

  // ==========================================================
  // INT
  // ==========================================================

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

  // ==========================================================
  // DOUBLE
  // ==========================================================

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

  // ==========================================================
  // DATE
  // ==========================================================

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

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

  // ==========================================================
  // TIME FORMAT
  // ==========================================================

  String _formatTime(
    DateTime date,
  ) {
    final int hour =
        date.hour;

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final String suffix =
        hour >= 12
            ? 'PM'
            : 'AM';

    final int displayHour =
        hour % 12 == 0
            ? 12
            : hour % 12;

    return '$displayHour:$minute $suffix';
  }
}
