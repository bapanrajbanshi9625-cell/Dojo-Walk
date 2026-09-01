import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WalkerRouteResult {
  const WalkerRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Remaining route from Walker to Owner.
  final List<LatLng> points;

  /// Remaining route distance in meters.
  final double distanceMeters;

  /// Estimated remaining travel time in seconds.
  final int durationSeconds;

  int get durationMinutes {
    if (durationSeconds <= 0) {
      return 0;
    }

    return (durationSeconds / 60).ceil();
  }

  String get distanceLabel {
    if (distanceMeters <= 0) {
      return '--';
    }

    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000;

      return km >= 10
          ? '${km.toStringAsFixed(0)} km'
          : '${km.toStringAsFixed(1)} km';
    }

    return '${distanceMeters.round()} m';
  }

  String get etaLabel {
    final minutes = durationMinutes;

    if (minutes <= 0) {
      return 'Arriving';
    }

    return minutes == 1
        ? '1 min'
        : '$minutes min';
  }
}

class WalkerRouteService {
  WalkerRouteService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  // ==========================================================
  // OSRM ROUTING
  // ==========================================================

  static const String _baseUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // ==========================================================
  // GET WALKER → OWNER ROUTE
  // ==========================================================

  Future<WalkerRouteResult?> getRoute({
    required LatLng walkerLocation,
    required LatLng ownerLocation,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/'
        '${walkerLocation.longitude},'
        '${walkerLocation.latitude};'
        '${ownerLocation.longitude},'
        '${ownerLocation.latitude}'
        '?overview=full'
        '&geometries=geojson'
        '&steps=false',
      );

      final response = await _client.get(
        url,
        headers: const {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body =
          jsonDecode(response.body);

      if (body is! Map<String, dynamic>) {
        return null;
      }

      if (body['code'] != 'Ok') {
        return null;
      }

      final routes = body['routes'];

      if (routes is! List ||
          routes.isEmpty) {
        return null;
      }

      final route = routes.first;

      if (route is! Map<String, dynamic>) {
        return null;
      }

      final distance =
          _readDouble(route['distance']);

      final duration =
          _readDouble(route['duration']);

      final geometry =
          route['geometry'];

      final points =
          _readGeometry(geometry);

      if (points.length < 2) {
        return null;
      }

      return WalkerRouteResult(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration.round(),
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // GEOJSON → LAT LNG
  // ==========================================================

  List<LatLng> _readGeometry(
    dynamic geometry,
  ) {
    if (geometry is! Map<String, dynamic>) {
      return const <LatLng>[];
    }

    final coordinates =
        geometry['coordinates'];

    if (coordinates is! List) {
      return const <LatLng>[];
    }

    final points = <LatLng>[];

    for (final coordinate in coordinates) {
      if (coordinate is! List ||
          coordinate.length < 2) {
        continue;
      }

      final longitude =
          _readNullableDouble(
        coordinate[0],
      );

      final latitude =
          _readNullableDouble(
        coordinate[1],
      );

      if (latitude == null ||
          longitude == null) {
        continue;
      }

      points.add(
        LatLng(
          latitude,
          longitude,
        ),
      );
    }

    return points;
  }

  // ==========================================================
  // NUMBER HELPERS
  // ==========================================================

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  double? _readNullableDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  void dispose() {
    _client.close();
  }
}
