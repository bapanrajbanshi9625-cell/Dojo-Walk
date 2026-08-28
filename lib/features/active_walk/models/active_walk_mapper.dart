import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'active_walk.dart';

class ActiveWalkMapper {
  const ActiveWalkMapper._();

  static ActiveWalk fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return fromMap(
      document.id,
      data,
    );
  }

  static ActiveWalk fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final String dogName =
        ActiveWalk.readString(
      data['dogName'],
    ).isNotEmpty
            ? ActiveWalk.readString(
                data['dogName'],
              )
            : ActiveWalk.readString(
                data['petName'],
              );

    final String dogBreed =
        ActiveWalk.readString(
      data['dogBreed'],
    ).isNotEmpty
            ? ActiveWalk.readString(
                data['dogBreed'],
              )
            : ActiveWalk.readString(
                data['breed'],
              );

    final String destinationAddress =
        _firstNonEmpty([
      data['address'],
      data['destinationAddress'],
    ]);

    final LatLng? walkerLocation =
        ActiveWalk.geoPointToLatLng(
      data['walkerLocation'],
    ) ??
        ActiveWalk.geoPointToLatLng(
          data['currentLocation'],
        );

    final LatLng? destination =
        ActiveWalk.geoPointToLatLng(
      data['ownerLocation'],
    ) ??
        ActiveWalk.geoPointToLatLng(
          data['destinationLocation'],
        );

    final List<LatLng> routePoints =
        _readRoutePoints(
      data['routePoints'],
    );

    return ActiveWalk(
      id: id,

      ownerId: ActiveWalk.readString(
        data['ownerId'],
      ),

      ownerName: ActiveWalk.readString(
        data['ownerName'],
      ),

      walkerId: ActiveWalk.readString(
        data['walkerId'],
      ),

      walkerUid: ActiveWalk.readString(
        data['walkerUid'],
      ),

      walkerName:
          ActiveWalk.readString(
        data['walkerName'],
      ).isEmpty
              ? 'Walker'
              : ActiveWalk.readString(
                  data['walkerName'],
                ),

      walkerPhone:
          ActiveWalk.readString(
        data['walkerPhone'],
      ),

      dogName:
          dogName.isEmpty ? 'Dog' : dogName,

      dogBreed:
          dogBreed.isEmpty
              ? 'Breed not available'
              : dogBreed,

      destinationAddress:
          destinationAddress.isEmpty
              ? 'Destination not available'
              : destinationAddress,

      walkerLocation: walkerLocation,

      destination: destination,

      routePoints: routePoints,

      startedAt: ActiveWalk.readDate(
        data['startedAt'],
      ),

      status:
          ActiveWalk.readString(
        data['status'],
      ).isEmpty
              ? 'active'
              : ActiveWalk.readString(
                  data['status'],
                ),

      distance:
          ActiveWalk.readString(
        data['distance'],
      ).isEmpty
              ? '0.0 km'
              : ActiveWalk.readString(
                  data['distance'],
                ),

      steps: ActiveWalk.readInt(
        data['steps'],
      ),

      peeCount: ActiveWalk.readInt(
        data['peeCount'],
      ),

      poopCount: ActiveWalk.readInt(
        data['poopCount'],
      ),
    );
  }

  static String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final String text =
          ActiveWalk.readString(value);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  static List<LatLng> _readRoutePoints(
    dynamic value,
  ) {
    if (value is! List) {
      return <LatLng>[];
    }

    final List<LatLng> points =
        <LatLng>[];

    for (final dynamic item in value) {
      final LatLng? point =
          ActiveWalk.geoPointToLatLng(item);

      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }
}
