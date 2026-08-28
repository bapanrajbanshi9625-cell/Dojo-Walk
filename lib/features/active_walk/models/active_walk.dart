import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class ActiveWalk {
  const ActiveWalk({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.walkerId,
    required this.walkerUid,
    required this.walkerName,
    required this.walkerPhone,
    required this.dogName,
    required this.dogBreed,
    required this.status,
    required this.walkerLocation,
    required this.ownerLocation,
    required this.address,
    required this.startedAt,
    required this.createdAt,
  });

  // ==========================================================
  // DOCUMENT
  // ==========================================================

  final String id;

  // ==========================================================
  // OWNER
  // ==========================================================

  final String ownerId;
  final String ownerName;

  // ==========================================================
  // WALKER
  // ==========================================================

  final String walkerId;
  final String walkerUid;
  final String walkerName;
  final String walkerPhone;

  // ==========================================================
  // DOG
  // ==========================================================

  final String dogName;
  final String dogBreed;

  // ==========================================================
  // STATUS
  // ==========================================================

  final String status;

  // ==========================================================
  // LOCATION
  // Firestore source type
  // ==========================================================

  final GeoPoint? walkerLocation;
  final GeoPoint? ownerLocation;

  // ==========================================================
  // ADDRESS
  // ==========================================================

  final String address;

  // ==========================================================
  // TIME
  // ==========================================================

  final DateTime? startedAt;
  final DateTime? createdAt;

  // ==========================================================
  // UI COMPATIBILITY GETTERS
  // ==========================================================

  /// Destination address used by ActiveWalkScreen.
  String get destinationAddress => address;

  /// Walker location converted from Firestore GeoPoint
  /// to flutter_map LatLng.
  LatLng? get walkerLatLng {
    final GeoPoint? location = walkerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  /// Owner location converted to LatLng.
  LatLng? get ownerLatLng {
    final GeoPoint? location = ownerLocation;

    if (location == null) {
      return null;
    }

    return LatLng(
      location.latitude,
      location.longitude,
    );
  }

  /// The map widgets use `destination`.
  ///
  /// For the current data model, the owner's saved location
  /// is the destination/pickup point.
  LatLng? get destination => ownerLatLng;

  /// Current route data.
  ///
  /// Until a dedicated route array is stored in Firestore,
  /// create a simple line from walker -> owner/destination.
  List<LatLng> get routePoints {
    final List<LatLng> points = [];

    final LatLng? walker = walkerLatLng;
    final LatLng? target = destination;

    if (walker != null) {
      points.add(walker);
    }

    if (target != null) {
      points.add(target);
    }

    return points;
  }

  // ==========================================================
  // WALK STATISTICS
  // ==========================================================

  /// Firestore distance is currently represented as a String.
  /// Example: "2.4 km".
  String get distance => '0.0 km';

  /// Current step count.
  ///
  /// If steps are added to Firestore later, this getter can
  /// be changed without touching the UI.
  int get steps => 0;

  /// Number of pee events.
  int get peeCount => 0;

  /// Number of poop events.
  int get poopCount => 0;

  // ==========================================================
  // NORMALIZED STATUS
  // ==========================================================

  String get normalizedStatus {
    return status
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  // ==========================================================
  // ACTIVE
  // ==========================================================

  bool get isActive {
    return normalizedStatus == 'active' ||
        normalizedStatus == 'accepted' ||
        normalizedStatus == 'on_the_way' ||
        normalizedStatus == 'on_that_way';
  }

  // ==========================================================
  // WALKER REACHED
  // ==========================================================

  bool get isWalkerReached {
    return normalizedStatus == 'reached';
  }

  // ==========================================================
  // LIVE WALK
  // ==========================================================

  bool get isLiveWalk {
    return normalizedStatus == 'walking' ||
        normalizedStatus == 'in_progress';
  }

  // ==========================================================
  // COMPLETED
  // ==========================================================

  bool get isCompleted {
    return normalizedStatus == 'completed' ||
        normalizedStatus == 'ended';
  }

  // ==========================================================
  // LOCATION HELPERS
  // ==========================================================

  bool get hasWalkerLocation {
    return walkerLocation != null;
  }

  bool get hasOwnerLocation {
    return ownerLocation != null;
  }
}
