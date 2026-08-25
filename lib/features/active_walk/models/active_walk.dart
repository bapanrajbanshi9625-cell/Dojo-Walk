import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalk {
  final String id;
  final String requestId;
  final String ownerId;
  final String ownerAuthUid;

  final String walkerId;
  final String walkerName;
  final String walkerPhone;

  final String petName;
  final String petBreed;

  final String status;

  final GeoPoint? ownerLocation;
  final GeoPoint? walkerLocation;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActiveWalk({
    required this.id,
    required this.requestId,
    required this.ownerId,
    required this.ownerAuthUid,
    required this.walkerId,
    required this.walkerName,
    required this.walkerPhone,
    required this.petName,
    required this.petBreed,
    required this.status,
    required this.ownerLocation,
    required this.walkerLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActiveWalk.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ActiveWalk(
      id: documentId,

      requestId: _string(
        data,
        const [
          'requestId',
          'requestID',
          'walkRequestId',
        ],
      ),

      ownerId: _string(
        data,
        const [
          'ownerId',
          'ownerID',
          'businessId',
        ],
      ),

      ownerAuthUid: _string(
        data,
        const [
          'ownerAuthUid',
          'ownerAuthUID',
          'authUid',
        ],
      ),

      walkerId: _string(
        data,
        const [
          'walkerId',
          'walkerID',
        ],
      ),

      walkerName: _string(
        data,
        const [
          'walkerName',
          'walker',
        ],
      ),

      walkerPhone: _string(
        data,
        const [
          'walkerPhone',
          'phone',
          'walkerMobile',
        ],
      ),

      petName: _string(
        data,
        const [
          'petName',
          'dogName',
          'Pet Name',
          'Dog Name',
        ],
      ),

      petBreed: _string(
        data,
        const [
          'petBreed',
          'dogBreed',
          'breed',
          'Pet Breed',
          'Dog Breed',
        ],
      ),

      status: _string(
        data,
        const [
          'status',
        ],
        fallback: 'accepted',
      ),

      ownerLocation: _geoPoint(
        data,
        const [
          'ownerLocation',
          'destinationLocation',
          'location',
          'ownerGeoPoint',
        ],
      ),

      walkerLocation: _geoPoint(
        data,
        const [
          'walkerLocation',
          'currentWalkerLocation',
          'walkerGeoPoint',
        ],
      ),

      createdAt: _dateTime(
        data['createdAt'],
      ),

      updatedAt: _dateTime(
        data['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'requestId': requestId,
      'ownerId': ownerId,
      'ownerAuthUid': ownerAuthUid,
      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerPhone': walkerPhone,
      'petName': petName,
      'petBreed': petBreed,
      'status': status,
      if (ownerLocation != null)
        'ownerLocation': ownerLocation,
      if (walkerLocation != null)
        'walkerLocation': walkerLocation,
      if (createdAt != null)
        'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null)
        'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  static String _string(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final dynamic value = data[key];

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

  static GeoPoint? _geoPoint(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value is GeoPoint) {
        return value;
      }

      if (value is Map) {
        final dynamic latitude =
            value['latitude'] ?? value['lat'];

        final dynamic longitude =
            value['longitude'] ??
                value['lng'] ??
                value['lon'];

        if (latitude is num &&
            longitude is num) {
          return GeoPoint(
            latitude.toDouble(),
            longitude.toDouble(),
          );
        }
      }
    }

    return null;
  }

  static DateTime? _dateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
