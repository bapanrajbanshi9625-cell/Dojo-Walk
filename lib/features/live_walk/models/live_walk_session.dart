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

  // ============================================================
  // IDENTITY
  // ============================================================

  final String documentId;
  final String walkId;

  // ============================================================
  // OWNER
  // ============================================================

  final String ownerId;
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;

  // ============================================================
  // WALKER
  // ============================================================

  final String walkerId;
  final String walkerUid;
  final String walkerName;
  final String walkerPhone;

  // ============================================================
  // DOG
  // ============================================================

  final String dogName;
  final String dogBreed;

  // ============================================================
  // STATUS
  // ============================================================

  final String status;

  final bool reached;
  final bool trackingStarted;
  final bool trackingEnded;
  final bool walkStarted;
  final bool walkEnded;

  // ============================================================
  // LOCATION
  // ============================================================

  final LatLng? walkerLocation;
  final LatLng? ownerLocation;

  // ============================================================
  // DESTINATION
  // ============================================================

  final String destinationAddress;

  // ============================================================
  // ROUTE
  // ============================================================

  final List<LatLng> routePoints;

  // ============================================================
  // WALK STATS
  // ============================================================

  final int elapsedSeconds;
  final double distanceKm;
  final int steps;
  final int peeCount;
  final int poopCount;

  final DateTime? startedAt;

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isCompleted {
    return trackingEnded ||
        walkEnded ||
        status == 'completed' ||
        status == 'ended' ||
        status == 'cancelled';
  }

  bool get isLive {
    return !isCompleted &&
        (trackingStarted || walkStarted);
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  String get durationLabel {
    final Duration duration =
        Duration(seconds: elapsedSeconds);

    final int hours = duration.inHours;

    final int minutes =
        duration.inMinutes.remainder(60);

    final int seconds =
        duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get distanceLabel {
    if (distanceKm <= 0) {
      return '0.0 km';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // ============================================================
  // FIRESTORE
  // ============================================================

  factory LiveWalkSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return LiveWalkSession.fromMap(
      document.id,
      data,
    );
  }

  factory LiveWalkSession.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return LiveWalkSession(
      documentId: documentId,

      // --------------------------------------------------------
      // WALK ID
      // --------------------------------------------------------

      walkId: _string(
        data['walkId'] ??
            data['walkRequestId'],
      ),

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      ownerId: _string(
        data['ownerId'],
      ),

      ownerUid: _string(
        data['ownerUid'] ??
            data['ownerAuthUid'],
      ),

      ownerName: _string(
        data['ownerName'],
        fallback: 'Owner',
      ),

      ownerPhone: _string(
        data['ownerPhone'],
      ),

      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

      walkerId: _string(
        data['walkerId'],
      ),

      walkerUid: _string(
        data['walkerUid'],
      ),

      walkerName: _string(
        data['walkerName'],
        fallback: 'Walker',
      ),

      walkerPhone: _string(
        data['walkerPhone'],
      ),

      // --------------------------------------------------------
      // DOG
      // --------------------------------------------------------

      dogName: _string(
        data['dogName'],
        fallback: 'Dog',
      ),

      dogBreed: _string(
        data['dogBreed'],
      ),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      status: _normalizeStatus(
        data['status'],
      ),

      reached:
          data['reached'] == true,

      trackingStarted:
          data['trackingStarted'] == true,

      trackingEnded:
          data['trackingEnded'] == true,

      walkStarted:
          data['walkStarted'] == true,

      walkEnded:
          data['walkEnded'] == true,

      // --------------------------------------------------------
      // WALKER LOCATION
      //
      // Supports:
      // 1. currentLocation = GeoPoint
      // 2. currentLocation = {lat, lng}
      // 3. currentLat + currentLng
      // --------------------------------------------------------

      walkerLocation:
          _readWalkerLocation(data),

      // --------------------------------------------------------
      // OWNER LOCATION
      //
      // Supports:
      // 1. destinationLocation
      // 2. ownerLocation
      // --------------------------------------------------------

      ownerLocation:
          _location(
            data['destinationLocation'],
          ) ??
          _location(
            data['ownerLocation'],
          ),

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      destinationAddress:
          _readAddress(
            data['address'],
            fallback:
                data['destinationAddress'],
          ),

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      routePoints:
          _route(
            data['routeCoordinates'],
          ),

      // --------------------------------------------------------
      // STATS
      // --------------------------------------------------------

      elapsedSeconds:
          _int(
            data['elapsedSeconds'] ??
                data['durationSeconds'],
          ),

      distanceKm:
          _double(
            data['distanceKm'],
          ),

      steps:
          _int(
            data['steps'],
          ),

      peeCount:
          _int(
            data['peeCount'],
          ),

      poopCount:
          _int(
            data['poopCount'],
          ),

      // --------------------------------------------------------
      // START TIME
      // --------------------------------------------------------

      startedAt:
          _date(
            data['startedAt'],
          ),
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    final String result =
        value?.toString().trim() ?? '';

    return result.isEmpty
        ? fallback
        : result;
  }

  // ============================================================
  // INT
  // ============================================================

  static int _int(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  static double _double(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ============================================================
  // WALKER LOCATION
  // ============================================================

  static LatLng? _readWalkerLocation(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // First: currentLocation
    // ----------------------------------------------------------

    final LatLng? currentLocation =
        _location(
      data['currentLocation'],
    );

    if (currentLocation != null) {
      return currentLocation;
    }

    // ----------------------------------------------------------
    // Second: currentLat + currentLng
    // ----------------------------------------------------------

    final double? lat =
        _nullableDouble(
      data['currentLat'],
    );

    final double? lng =
        _nullableDouble(
      data['currentLng'],
    );

    if (lat == null || lng == null) {
      return null;
    }

    if (lat == 0 && lng == 0) {
      return null;
    }

    if (lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }

    return LatLng(
      lat,
      lng,
    );
  }

  // ============================================================
  // LOCATION PARSER
  // ============================================================

  static LatLng? _location(
    dynamic value,
  ) {
    double? lat;
    double? lng;

    // GeoPoint
    if (value is GeoPoint) {
      lat = value.latitude;
      lng = value.longitude;
    }

    // Map
    else if (value is Map) {
      lat = _nullableDouble(
        value['lat'] ??
            value['latitude'],
      );

      lng = _nullableDouble(
        value['lng'] ??
            value['longitude'],
      );
    }

    if (lat == null ||
        lng == null) {
      return null;
    }

    // Invalid Firestore default
    if (lat == 0 && lng == 0) {
      return null;
    }

    // Invalid coordinates
    if (lat < -90 ||
        lat > 90 ||
        lng < -180 ||
        lng > 180) {
      return null;
    }

    return LatLng(
      lat,
      lng,
    );
  }

  // ============================================================
  // NULLABLE DOUBLE
  // ============================================================

  static double? _nullableDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ============================================================
  // ROUTE
  // ============================================================

  static List<LatLng> _route(
    dynamic value,
  ) {
    if (value is! List) {
      return const <LatLng>[];
    }

    final List<LatLng> result =
        <LatLng>[];

    for (final dynamic item in value) {
      final LatLng? point =
          _location(item);

      if (point != null) {
        result.add(point);
      }
    }

    return result;
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  static String _readAddress(
    dynamic value, {
    dynamic fallback,
  }) {
    // ----------------------------------------------------------
    // Address stored as Map
    // ----------------------------------------------------------

    if (value is Map) {
      final String addressLine1 =
          _string(
        value['addressLine1'],
      );

      final String area =
          _string(
        value['area'],
      );

      final String city =
          _string(
        value['city'],
      );

      final List<String> parts =
          <String>[
        if (addressLine1.isNotEmpty)
          addressLine1,
        if (area.isNotEmpty)
          area,
        if (city.isNotEmpty)
          city,
      ];

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    // ----------------------------------------------------------
    // Address stored as String
    // ----------------------------------------------------------

    final String text =
        _string(value);

    if (text.isNotEmpty) {
      return text;
    }

    // ----------------------------------------------------------
    // Fallback
    // ----------------------------------------------------------

    final String fallbackText =
        _string(fallback);

    if (fallbackText.isNotEmpty) {
      return fallbackText;
    }

    return 'Destination not available';
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime? _date(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // STATUS NORMALIZER
  // ============================================================

  static String _normalizeStatus(
    dynamic value,
  ) {
    return _string(value)
        .toLowerCase()
        .trim()
        .replaceAll(
          '-',
          '_',
        )
        .replaceAll(
          ' ',
          '_',
        );
  }
}
