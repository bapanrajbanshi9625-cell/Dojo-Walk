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
    required this.destinationAddress,
    required this.walkerLocation,
    required this.destination,
    required this.routePoints,
    required this.startedAt,
    required this.status,
    required this.distance,
    required this.steps,
    required this.peeCount,
    required this.poopCount,
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

  final String destinationAddress;

  final LatLng? walkerLocation;
  final LatLng? destination;

  final List<LatLng> routePoints;

  final DateTime? startedAt;

  final String status;

  final String distance;
  final int steps;
  final int peeCount;
  final int poopCount;

  bool get isActive {
    return status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'started' ||
        status.toLowerCase() == 'in_progress' ||
        status.toLowerCase() == 'ongoing';
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'ended';
  }

  Duration? get elapsed {
    if (startedAt == null) {
      return null;
    }

    return DateTime.now().difference(startedAt!);
  }

  static LatLng? geoPointToLatLng(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is Map) {
      final dynamic lat =
          value['latitude'] ?? value['lat'];

      final dynamic lng =
          value['longitude'] ?? value['lng'];

      final double? latitude =
          double.tryParse(lat?.toString() ?? '');

      final double? longitude =
          double.tryParse(lng?.toString() ?? '');

      if (latitude != null &&
          longitude != null) {
        return LatLng(
          latitude,
          longitude,
        );
      }
    }

    return null;
  }

  static DateTime? readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int readInt(dynamic value) {
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
}
