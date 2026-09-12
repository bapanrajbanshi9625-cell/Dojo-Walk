import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class LiveWalkSession {
  const LiveWalkSession({
    required this.documentId,
    required this.requestId,
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
  final String requestId;

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

  String get walkId => requestId;

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

    // ==========================================================
    // WALKER LOCATION
    //
    // Priority:
    // 1. currentLocation
    // 2. walkerLocation
    // 3. walkerCurrentLocation
    // 4. lastLocation
    // 5. walkerLatitude / walkerLongitude
    // 6. currentLat / currentLng
    //
    // This matches the Walker live tracking architecture.
    // ==========================================================

    final LatLng? walkerLocation = _readFirstLocation(
      <dynamic>[
        data['currentLocation'],
        data['walkerLocation'],
        data['walkerCurrentLocation'],
        data['lastLocation'],
      ],
    ) ??
        _readLatLng(
          data['walkerLatitude'],
          data['walkerLongitude'],
        ) ??
        _readLatLng(
          data['currentLat'],
          data['currentLng'],
        );

    // ==========================================================
    // OWNER LOCATION
    // ==========================================================

    final LatLng? ownerLocation = _readLocation(
      data['ownerLocation'],
      fallbackLat: _readNestedDouble(
        data['address'],
        'latitude',
      ),
      fallbackLng: _readNestedDouble(
        data['address'],
        'longitude',
      ),
    );

    final List<LatLng> routePoints = _readRoute(
      data['routeCoordinates'],
    );

    // ==========================================================
    // CANONICAL WALK ID
    // ==========================================================

    final String requestId = _readString(
      data['requestId'],
      fallback: snapshot.id,
    );

    return LiveWalkSession(
      documentId: snapshot.id,
      requestId: requestId,

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

  // ============================================================
  // STRING
  // ============================================================

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final String result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  // ============================================================
  // BOOL
  // ============================================================

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

  // ============================================================
  // INT
  // ============================================================

  static int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) return value;

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  static double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  // ============================================================
  // DATETIME
  // ============================================================

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

  // ============================================================
  // LOCATION LIST
  // ============================================================

  static LatLng? _readFirstLocation(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final LatLng? location = _readLocation(value);

      if (location != null) {
        return location;
      }
    }

    return null;
  }

  // ============================================================
  // LAT/LNG PAIR
  // ============================================================

  static LatLng? _readLatLng(
    dynamic latitude,
    dynamic longitude,
  ) {
    final double? lat = _nullableDouble(latitude);
    final double? lng = _nullableDouble(longitude);

    if (lat == null || lng == null) {
      return null;
    }

    if (!_validCoordinate(lat, lng)) {
      return null;
    }

    return LatLng(lat, lng);
  }

  // ============================================================
  // LOCATION
  // ============================================================

  static LatLng? _readLocation(
    dynamic value, {
    double fallbackLat = 0,
    double fallbackLng = 0,
  }) {
    if (value is GeoPoint) {
      if (!_validCoordinate(
        value.latitude,
        value.longitude,
      )) {
        return null;
      }

      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is Map) {
      final double? lat = _nullableDouble(
        value['lat'] ?? value['latitude'],
      );

      final double? lng = _nullableDouble(
        value['lng'] ?? value['longitude'],
      );

      if (lat != null &&
          lng != null &&
          _validCoordinate(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    if (_validCoordinate(
      fallbackLat,
      fallbackLng,
    )) {
      return LatLng(
        fallbackLat,
        fallbackLng,
      );
    }

    return null;
  }

  // ============================================================
  // COORDINATE VALIDATION
  // ============================================================

  static bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  static double? _nullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static double _toDouble(dynamic value) {
    return _nullableDouble(value) ?? 0;
  }

  // ============================================================
  // NESTED DOUBLE
  // ============================================================

  static double _readNestedDouble(
    dynamic value,
    String key,
  ) {
    if (value is Map) {
      return _toDouble(value[key]);
    }

    return 0;
  }

  // ============================================================
  // ROUTE
  // ============================================================

  static List<LatLng> _readRoute(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final List<LatLng> result = <LatLng>[];

    for (final dynamic item in value) {
      if (item is GeoPoint) {
        if (_validCoordinate(
          item.latitude,
          item.longitude,
        )) {
          result.add(
            LatLng(
              item.latitude,
              item.longitude,
            ),
          );
        }

        continue;
      }

      if (item is Map) {
        final double? lat = _nullableDouble(
          item['lat'] ?? item['latitude'],
        );

        final double? lng = _nullableDouble(
          item['lng'] ?? item['longitude'],
        );

        if (lat != null &&
            lng != null &&
            _validCoordinate(lat, lng)) {
          result.add(
            LatLng(lat, lng),
          );
        }
      }
    }

    return result;
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  static String _readAddress(
    Map<String, dynamic> data,
  ) {
    final String direct = _readString(
      data['destinationAddress'],
    );

    if (direct.isNotEmpty) {
      return direct;
    }

    final dynamic address = data['address'];

    if (address is String) {
      return address;
    }

    if (address is Map) {
      final List<String> parts = <String>[
        _readString(address['flatNumber']),
        _readString(address['addressLine1']),
        _readString(address['addressLine2']),
        _readString(address['area']),
        _readString(address['city']),
        _readString(address['state']),
        _readString(address['pincode']),
      ].where((String item) => item.isNotEmpty).toList();

      return parts.join(', ');
    }

    return '';
  }
}
