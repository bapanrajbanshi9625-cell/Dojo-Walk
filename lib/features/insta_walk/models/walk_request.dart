import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;
  final String ownerId;
  final String ownerName;
  final String dogName;
  final String pickupAddress;
  final double distanceKm;
  final String estimatedTime;
  final GeoPoint? ownerLocation;
  final String status;

  const WalkRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.dogName,
    required this.pickupAddress,
    required this.distanceKm,
    required this.estimatedTime,
    required this.ownerLocation,
    required this.status,
  });

  factory WalkRequest.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: id,
      ownerId: _string(
        data,
        const [
          'ownerId',
          'businessId',
        ],
      ),
      ownerName: _string(
        data,
        const [
          'ownerName',
          'name',
        ],
      ),
      dogName: _string(
        data,
        const [
          'dogName',
          'petName',
        ],
        fallback: 'Dog',
      ),
      pickupAddress: _string(
        data,
        const [
          'address',
          'pickupAddress',
          'Adress',
        ],
        fallback: 'Address not available',
      ),
      distanceKm: _double(
        data['distanceKm'],
      ),
      estimatedTime: _string(
        data,
        const [
          'estimatedTime',
          'routeDuration',
        ],
        fallback: 'Nearby',
      ),
      ownerLocation: _geoPoint(
        data,
        const [
          'ownerLocation',
          'destinationLocation',
          'location',
        ],
      ),
      status: _string(
        data,
        const ['status'],
        fallback: 'searching',
      ),
    );
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

      final String text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static double _double(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
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
        final dynamic lat =
            value['latitude'] ?? value['lat'];

        final dynamic lng =
            value['longitude'] ??
                value['lng'] ??
                value['lon'];

        if (lat is num && lng is num) {
          return GeoPoint(
            lat.toDouble(),
            lng.toDouble(),
          );
        }
      }
    }

    return null;
  }
}
