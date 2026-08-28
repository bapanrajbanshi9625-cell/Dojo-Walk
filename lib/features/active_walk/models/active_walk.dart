import 'package:cloud_firestore/cloud_firestore.dart';

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
  // DOCUMENT ID
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
  // ==========================================================

  final GeoPoint? walkerLocation;
  final GeoPoint? ownerLocation;

  // ==========================================================
  // DESTINATION
  // ==========================================================

  final String address;

  // ==========================================================
  // TIME
  // ==========================================================

  final DateTime? startedAt;
  final DateTime? createdAt;

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
  //
  // Walker is still coming / active pickup phase.
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
  // ACTUAL WALK / LIVE WALK
  //
  // This is where live_walk_screen.dart is used.
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
  // WALKER LOCATION AVAILABLE
  // ==========================================================

  bool get hasWalkerLocation {
    return walkerLocation != null;
  }

  // ==========================================================
  // OWNER LOCATION AVAILABLE
  // ==========================================================

  bool get hasOwnerLocation {
    return ownerLocation != null;
  }
}
