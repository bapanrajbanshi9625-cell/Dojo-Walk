import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkAcceptedData {
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

  // ==========================================================
  // LOCATION
  // ==========================================================

  final GeoPoint? ownerLocation;

  // ==========================================================
  // ACCEPTED
  // ==========================================================

  final DateTime? acceptedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const InstaWalkAcceptedData({
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
    this.ownerLocation,
    this.acceptedAt,
  });

  // ==========================================================
  // FROM FIRESTORE MAP
  // ==========================================================

  factory InstaWalkAcceptedData.fromMap(
    Map<String, dynamic> map, {
    String requestId = '',
  }) {
    return InstaWalkAcceptedData(
      // ======================================================
      // REQUEST ID
      // ======================================================

      requestId: requestId.trim().isNotEmpty
          ? requestId.trim()
          : _readString(
              map['requestId'],
            ),

      // ======================================================
      // OWNER
      // ======================================================

      ownerId: _readString(
        map['ownerId'],
      ),

      ownerName: _readString(
        map['ownerName'],
        fallback: 'Dog Owner',
      ),

      address: _readFirstString(
        map,
        const [
          'address',
          'Adress',
          'Address',
        ],
      ),

      // ======================================================
      // DOG NAME
      //
      // Firestore/Admin compatibility:
      // dogName → petName → Dog Name
      // ======================================================

      dogName: _readFirstString(
        map,
        const [
          'dogName',
          'petName',
          'Dog Name',
          'Pet Name',
        ],
        fallback: 'Your Dog',
      ),

      // ======================================================
      // DOG BREED
      //
      // Firestore/Admin compatibility:
      // dogBreed → breed → Dog Breed
      // ======================================================

      dogBreed: _readFirstString(
        map,
        const [
          'dogBreed',
          'breed',
          'Dog Breed',
          'Breed',
        ],
        fallback: 'Breed not available',
      ),

      // ======================================================
      // WALKER
      // ======================================================

      walkerId: _readString(
        map['walkerId'],
      ),

      walkerUid: _readString(
        map['walkerUid'],
      ),

      walkerName: _readString(
        map['walkerName'],
        fallback: 'Walker',
      ),

      walkerPhone: _readNullableString(
        map['walkerPhone'],
      ),

      // ======================================================
      // OWNER LOCATION
      //
      // Used by OSM map.
      // ======================================================

      ownerLocation:
          map['ownerLocation'] is GeoPoint
              ? map['ownerLocation'] as GeoPoint
              : null,

      // ======================================================
      // ACCEPTED AT
      // ======================================================

      acceptedAt: _parseDate(
        map['acceptedAt'],
      ),
    );
  }

  // ==========================================================
  // FROM FIRESTORE DOCUMENT
  // ==========================================================

  factory InstaWalkAcceptedData.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return InstaWalkAcceptedData.fromMap(
      data,
      requestId: document.id,
    );
  }

  // ==========================================================
  // READ FIRST AVAILABLE STRING
  // ==========================================================

  static String _readFirstString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final dynamic value = map[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return fallback;
  }

  // ==========================================================
  // STRING HELPER
  // ==========================================================

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // ==========================================================
  // NULLABLE STRING HELPER
  // ==========================================================

  static String? _readNullableString(
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
  // DATE PARSER
  // ==========================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    // Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // Native DateTime
    if (value is DateTime) {
      return value;
    }

    // String fallback
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
