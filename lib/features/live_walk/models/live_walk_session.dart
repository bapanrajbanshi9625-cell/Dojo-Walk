import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class LiveWalkSession {
  const LiveWalkSession({
    required this.documentId,
    required this.walkId,
    required this.ownerId,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkerId,
    required this.walkerUid,
    required this.walkerName,
    required this.walkerPhone,
    required this.walkerPhoto,
    required this.dogName,
    required this.dogBreed,
    required this.status,
    required this.reached,
    required this.trackingStarted,
    required this.trackingEnded,
    required this.walkStarted,
    required this.walkEnded,
    required this.walkerLocation,
    required this.ownerLocation,
    required this.destinationAddress,
    required this.routePoints,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.steps,
    required this.peeCount,
    required this.poopCount,
    required this.startedAt,
  });

  final String documentId;
  final String walkId;

  final String ownerId;
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;

  final String walkerId;
  final String walkerUid;
  final String walkerName;
  final String walkerPhone;
  final String walkerPhoto;

  final String dogName;
  final String dogBreed;

  final String status;

  final bool reached;
  final bool trackingStarted;
  final bool trackingEnded;
  final bool walkStarted;
  final bool walkEnded;

  final LatLng? walkerLocation;
  final LatLng? ownerLocation;

  final String destinationAddress;
  final List<LatLng> routePoints;

  final int elapsedSeconds;
  final double distanceKm;
  final int steps;
  final int peeCount;
  final int poopCount;

  final DateTime? startedAt;

  bool get isCompleted {
    final normalized = status.toLowerCase();

    return trackingEnded ||
        walkEnded ||
        normalized == 'completed' ||
        normalized == 'ended' ||
        normalized == 'cancelled';
  }

  bool get isLive {
    return !isCompleted && (trackingStarted || walkStarted);
  }

  String get durationLabel {
    final totalMinutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get distanceLabel {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  factory LiveWalkSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    final walkerLocation = _readLocation(
      data['currentLocation'],
      fallbackLat: _toDouble(data['currentLat']),
      fallbackLng: _toDouble(data['currentLng']),
    );

    final ownerLocation = _readLocation(
      data['ownerLocation'],
      fallbackLat: _readNestedDouble(data['address'], 'latitude'),
      fallbackLng: _readNestedDouble(data['address'], 'longitude'),
    );

    final routePoints = _readRoute(data['routeCoordinates']);

    return LiveWalkSession(
      documentId: snapshot.id,

      walkId: _readString(
        data['walkId'],
        fallback: _readString(data['walkRequestId']),
      ),

      ownerId: _readString(data['ownerId']),
      ownerUid: _readString(
        data['ownerUid'],
        fallback: _readString(data['ownerAuthUid']),
      ),
      ownerName: _readString(data['ownerName']),
      ownerPhone: _readString(data['ownerPhone']),

      walkerId: _readString(data['walkerId']),
      walkerUid: _readString(data['walkerUid']),
      walkerName: _readString(data['walkerName']),
      walkerPhone: _readString(data['walkerPhone']),

      // IMPORTANT:
      // Walker profile photo comes directly from liveWalkSessions.
      walkerPhoto: _readString(
       data['walkerProfileImage'],
       fallback: _readString( 
        data['walkerPhoto'],
        fallback: _readString(data['walkerPhotoUrl']),
       ),
      ),

      dogName: _readString(data['dogName']),
      dogBreed: _readString(data['dogBreed']),

      status: _readString(data['status']),

      reached: _readBool(data['reached']),
      trackingStarted: _readBool(data['trackingStarted']),
      trackingEnded: _readBool(data['trackingEnded']),
      walkStarted: _readBool(data['walkStarted']),
      walkEnded: _readBool(data['walkEnded']),

      walkerLocation: walkerLocation,
      ownerLocation: ownerLocation,

      destinationAddress: _readAddress(data),

      routePoints: routePoints,

      elapsedSeconds: _readInt(
        data['elapsedSeconds'],
        fallback: _readInt(data['durationSeconds']),
      ),

      distanceKm: _readDouble(
        data['distanceKm'],
        fallback: _readDouble(data['distanceMeters']) / 1000,
      ),

      steps: _readInt(data['steps']),
      peeCount: _readInt(data['peeCount']),
      poopCount: _readInt(data['poopCount']),

      startedAt: _readDateTime(data['startedAt']),
    );
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return value.toLowerCase() == 'true';
    }

    return false;
  }

  static int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) return value;
    if (value is num) return value.round();

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
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

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static double _readNestedDouble(
    dynamic value,
    String key,
  ) {
    if (value is Map) {
      return _toDouble(value[key]);
    }

    return 0;
  }

  static LatLng? _readLocation(
    dynamic value, {
    double fallbackLat = 0,
    double fallbackLng = 0,
  }) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }

    if (value is Map) {
      final lat = _toDouble(value['lat'] ?? value['latitude']);
      final lng = _toDouble(value['lng'] ?? value['longitude']);

      if (lat != 0 || lng != 0) {
        return LatLng(lat, lng);
      }
    }

    if (fallbackLat != 0 || fallbackLng != 0) {
      return LatLng(fallbackLat, fallbackLng);
    }

    return null;
  }

  static List<LatLng> _readRoute(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final result = <LatLng>[];

    for (final item in value) {
      if (item is GeoPoint) {
        result.add(
          LatLng(item.latitude, item.longitude),
        );
        continue;
      }

      if (item is Map) {
        final lat = _toDouble(item['lat'] ?? item['latitude']);
        final lng = _toDouble(item['lng'] ?? item['longitude']);

        if (lat != 0 || lng != 0) {
          result.add(LatLng(lat, lng));
        }
      }
    }

    return result;
  }

  static String _readAddress(
    Map<String, dynamic> data,
  ) {
    final direct = _readString(data['destinationAddress']);

    if (direct.isNotEmpty) {
      return direct;
    }

    final address = data['address'];

    if (address is String) {
      return address;
    }

    if (address is Map) {
      final parts = <String>[
        _readString(address['flatNumber']),
        _readString(address['addressLine1']),
        _readString(address['addressLine2']),
        _readString(address['area']),
        _readString(address['city']),
        _readString(address['state']),
        _readString(address['pincode']),
      ].where((item) => item.isNotEmpty).toList();

      return parts.join(', ');
    }

    return '';
  }
}
