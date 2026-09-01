import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class WalkerLocationService {
  WalkerLocationService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  StreamSubscription<Position>? _positionSubscription;

  static const String _collection = 'walk_request';

  // ==========================================================
  // START LIVE LOCATION
  // ==========================================================

  Future<void> startTracking({
    required String requestId,
  }) async {
    final id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    await _ensureLocationPermission();

    await stopTracking();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        unawaited(
          _updateLocation(
            requestId: id,
            position: position,
          ),
        );
      },
      onError: (Object error) {
        // Location errors should not crash the app.
      },
    );
  }

  // ==========================================================
  // UPDATE FIRESTORE
  // ==========================================================

  Future<void> _updateLocation({
    required String requestId,
    required Position position,
  }) async {
    try {
      final updates = <String, dynamic>{
        'walkerLocation': GeoPoint(
          position.latitude,
          position.longitude,
        ),
        'walkerHeading': position.heading,
        'walkerSpeed': position.speed,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_collection)
          .doc(requestId)
          .update(updates);
    } catch (_) {
      // The next GPS update will retry naturally.
    }
  }

  // ==========================================================
  // STOP LIVE LOCATION
  // ==========================================================

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // ==========================================================
  // PERMISSION
  // ==========================================================

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError(
        'Location services are disabled.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is not available.',
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<void> dispose() async {
    await stopTracking();
  }
}
