import 'package:cloud_firestore/cloud_firestore.dart';

import 'active_walk.dart';

class ActiveWalkMapper {
  const ActiveWalkMapper._();

  static ActiveWalk fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return ActiveWalk(
      id: document.id,

      ownerId: _string(data['ownerId']),
      ownerName: _string(data['ownerName']),

      walkerId: _string(data['walkerId']),
      walkerUid: _string(data['walkerUid']),
      walkerName: _string(data['walkerName']),
      walkerPhone: _string(data['walkerPhone']),

      dogName: _dogName(data),
      dogBreed: _dogBreed(data),

      status: _status(data),

      walkerLocation:
          _geoPoint(
        data['walkerLocation'] ??
            data['currentLocation'],
      ),

      ownerLocation:
          _geoPoint(
        data['ownerLocation'] ??
            data['destinationLocation'],
      ),

      address: _address(data),

      startedAt:
          _date(data['startedAt']),

      createdAt:
          _date(data['createdAt']),
    );
  }

  // ==========================================================
  // STRING
  // ==========================================================

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // DOG NAME
  // ==========================================================

  static String _dogName(
    Map<String, dynamic> data,
  ) {
    final String dogName =
        _string(data['dogName']);

    if (dogName.isNotEmpty) {
      return dogName;
    }

    final String petName =
        _string(data['petName']);

    if (petName.isNotEmpty) {
      return petName;
    }

    return 'Dog';
  }

  // ==========================================================
  // DOG BREED
  // ==========================================================

  static String _dogBreed(
    Map<String, dynamic> data,
  ) {
    final String breed =
        _string(data['dogBreed']);

    if (breed.isNotEmpty) {
      return breed;
    }

    final String alternate =
        _string(data['breed']);

    if (alternate.isNotEmpty) {
      return alternate;
    }

    return 'Breed not available';
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  static String _status(
    Map<String, dynamic> data,
  ) {
    final String status =
        _string(data['status']).toLowerCase();

    if (status.isEmpty) {
      return 'active';
    }

    return status;
  }

  // ==========================================================
  // ADDRESS
  // ==========================================================

  static String _address(
    Map<String, dynamic> data,
  ) {
    final String address =
        _string(data['address']);

    if (address.isNotEmpty) {
      return address;
    }

    final String destination =
        _string(data['destinationAddress']);

    if (destination.isNotEmpty) {
      return destination;
    }

    return 'Address not available';
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

    if (value is Map) {
      final dynamic latitude =
          value['latitude'] ?? value['lat'];

      final dynamic longitude =
          value['longitude'] ?? value['lng'];

      final double? lat =
          double.tryParse(
        latitude?.toString() ?? '',
      );

      final double? lng =
          double.tryParse(
        longitude?.toString() ?? '',
      );

      if (lat != null && lng != null) {
        return GeoPoint(lat, lng);
      }
    }

    return null;
  }

  // ==========================================================
  // DATE
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
