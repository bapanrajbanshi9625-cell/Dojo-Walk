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

  final String id;

  final String ownerId;
  final String ownerName;

  final String walkerId;
  final String walkerUid;
  final String walkerName;
  final String walkerPhone;

  final String dogName;
  final String dogBreed;

  final String status;

  final GeoPoint? walkerLocation;
  final GeoPoint? ownerLocation;

  final String address;

  final DateTime? startedAt;
  final DateTime? createdAt;

  bool get isActive =>
      status == 'active' ||
      status == 'accepted' ||
      status == 'on_the_way';

  bool get isWalkerReached =>
      status == 'reached';

  bool get isLiveWalk =>
      status == 'walking' ||
      status == 'in_progress';

  bool get isCompleted =>
      status == 'completed';
}
