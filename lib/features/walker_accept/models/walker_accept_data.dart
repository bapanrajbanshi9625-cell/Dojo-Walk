import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// WALKER ACCEPT DATA
/// ============================================================
///
/// Data model for the Owner-side Walker Accept screen.
///
/// Firestore flow:
///
/// walk_request/{requestId}
///
/// status:
///   accepted
///      ↓
///   reached
///
/// IMPORTANT:
/// - No active_walks collection is used here.
/// - The same walk_request document is used from Accept → Reached.
/// - After Reached, the Live Walk session can be created.
///
class WalkerAcceptData {
  const WalkerAcceptData({
    required this.requestId,
    required this.ownerId,
    required this.ownerName,
    required this.address,
    required this.dogName,
    required this.dogBreed,
    required this.walkerId,
    required this.walkerUid,
    required this.walkerName,
    this.walkerPhone,
    this.walkerProfileImage,
    this.walkerRating,
    this.ownerLocation,
    this.walkerLocation,
    this.walkerHeading,
    this.walkerSpeed,
    this.status = 'accepted',
    this.reached = false,
    this.acceptedAt,
    this.reachedAt,
    this.distanceMeters = 0,
    this.distanceKm = 0,
    this.etaMinutes = 0,
    this.updatedAt,
  });

  // ==========================================================
  // REQUEST
  // ==========================================================

  final String requestId;

  // ==========================================================
  // OWNER
  // ==========================================================

  final String ownerId;
  final String ownerName;
  final String address;

  // ==========================================================
  // DOG
  // ==========================================================

  final String dogName;
  final String dogBreed;

  // ==========================================================
  // WALKER
  // ==========================================================

  final String walkerId;
  final String walkerUid;
  final String walkerName;

  final String? walkerPhone;
  final String? walkerProfileImage;
  final double? walkerRating;

  // ==========================================================
  // LOCATIONS
  // ==========================================================

  /// Owner's saved Firestore location.
  final GeoPoint? ownerLocation;

  /// Walker's current live location.
  ///
  /// This should be updated by the Walker app while travelling
  /// to the Owner.
  final GeoPoint? walkerLocation;

  /// Walker's current direction in degrees.
  final double? walkerHeading;

  /// Walker's current speed.
  final double? walkerSpeed;

  // ==========================================================
  // REQUEST STATUS
  // ==========================================================

  final String status;

  /// True after Walker reaches Owner.
  final bool reached;

  final DateTime? acceptedAt;
  final DateTime? reachedAt;

  // ==========================================================
  // DISTANCE / ETA
  // ==========================================================

  /// Remaining arrival distance in meters.
  final int distanceMeters;

  /// Remaining arrival distance in kilometers.
  final double distanceKm;

  /// Remaining arrival duration in minutes.
  final int etaMinutes;

  final DateTime? updatedAt;

  // ==========================================================
  // STATUS HELPERS
  // ==========================================================

  bool get isAccepted =>
      status.trim().toLowerCase() == 'accepted';

  bool get isReached =>
      reached ||
      status.trim().toLowerCase() == 'reached';

  bool get isOnTheWay =>
      !isReached &&
      (isAccepted || status.trim().isNotEmpty);

  // ==========================================================
  // LOCATION HELPERS
  // ==========================================================

  bool get hasOwnerLocation =>
      ownerLocation != null;

  bool get hasWalkerLocation =>
      walkerLocation != null;

  // ==========================================================
  // ETA HELPERS
  // ==========================================================

  int get etaSeconds =>
      etaMinutes * 60;

  String get etaLabel {
    if (isReached) {
      return 'Arrived';
    }

    if (etaMinutes <= 0) {
      return 'Calculating';
    }

    if (etaMinutes == 1) {
      return '1 min';
    }

    return '$etaMinutes min';
  }

  // ==========================================================
  // DISTANCE LABEL
  // ==========================================================

  String get distanceLabel {
    double meters = distanceMeters.toDouble();

    // Fallback to kilometer field if meters is unavailable.
    if (meters <= 0 && distanceKm > 0) {
      meters = distanceKm * 1000;
    }

    if (meters <= 0) {
      return '--';
    }

    if (meters >= 1000) {
      final double km = meters / 1000;

      if (km >= 10) {
        return '${km.toStringAsFixed(0)} km';
      }

      return '${km.toStringAsFixed(1)} km';
    }

    return '${meters.round()} m';
  }

  // ==========================================================
  // FIRESTORE FACTORY
  // ==========================================================

  factory WalkerAcceptData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return WalkerAcceptData.fromMap(
      document.data() ?? <String, dynamic>{},
      requestId: document.id,
    );
  }

  // ==========================================================
  // MAP FACTORY
  // ==========================================================

  factory WalkerAcceptData.fromMap(
    Map<String, dynamic> data, {
    String requestId = '',
  }) {
    return WalkerAcceptData(
      requestId: requestId.trim().isNotEmpty
          ? requestId.trim()
          : _string(data['requestId']),

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      ownerId: _firstString(
        data,
        const [
          'ownerId',
          'businessId',
        ],
      ),

      ownerName: _firstString(
        data,
        const [
          'ownerName',
          'name',
        ],
        fallback: 'Dog Owner',
      ),

      address: _firstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      ),

      // --------------------------------------------------------
      // DOG
      // --------------------------------------------------------

      dogName: _firstString(
        data,
        const [
          'dogName',
          'petName',
          'Dog Name',
          'Pet Name',
        ],
        fallback: 'Your Dog',
      ),

      dogBreed: _firstString(
        data,
        const [
          'dogBreed',
          'breed',
          'Dog Breed',
          'Breed',
        ],
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

      walkerName: _firstString(
        data,
        const [
          'walkerName',
          'Walker Name',
        ],
        fallback: 'Walker',
      ),

      walkerPhone: _nullableString(
        data['walkerPhone'],
      ),

      walkerProfileImage:
          _firstNullableString(
        data,
        const [
          'walkerProfileImage',
          'walkerPhoto',
          'profileImage',
          'profileImageUrl',
        ],
      ),

      walkerRating:
          _nullableDouble(
        data['walkerRating'],
      ),

      // --------------------------------------------------------
      // LOCATIONS
      // --------------------------------------------------------

      ownerLocation:
          _geoPoint(
        data['ownerLocation'],
      ),

      walkerLocation:
          _geoPoint(
        data['walkerLocation'],
      ),

      walkerHeading:
          _nullableDouble(
        data['walkerHeading'],
      ),

      walkerSpeed:
          _nullableDouble(
        data['walkerSpeed'],
      ),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      status: _firstString(
        data,
        const [
          'status',
        ],
        fallback: 'accepted',
      ),

      reached:
          data['reached'] == true,

      acceptedAt:
          _date(data['acceptedAt']),

      reachedAt:
          _date(data['reachedAt']),

      // --------------------------------------------------------
      // ARRIVAL DATA
      //
      // Matches your Firestore:
      //
      // arrivalDistanceMeters
      // arrivalDistanceKm
      // arrivalDurationMinutes
      // --------------------------------------------------------

      distanceMeters:
          _int(
        data['arrivalDistanceMeters'],
      ),

      distanceKm:
          _double(
        data['arrivalDistanceKm'],
      ),

      etaMinutes:
          _int(
        data['arrivalDurationMinutes'],
      ),

      updatedAt:
          _date(data['updatedAt']),
    );
  }

  // ==========================================================
  // STRING HELPERS
  // ==========================================================

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final String value =
          _string(data[key]);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  static String? _firstNullableString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String? value =
          _nullableString(data[key]);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static String _string(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final String valueString =
        _string(value);

    if (valueString.isEmpty) {
      return null;
    }

    return valueString;
  }

  // ==========================================================
  // NUMBER HELPERS
  // ==========================================================

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

  static double? _nullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int _int(
    dynamic value,
  ) {
    if (value is num) {
      return value.round();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ==========================================================
  // GEOPOINT
  // ==========================================================

  static GeoPoint? _geoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  // ==========================================================
  // DATE / TIMESTAMP
  // ==========================================================

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
      return DateTime.tryParse(value);
    }

    return null;
  }
}
