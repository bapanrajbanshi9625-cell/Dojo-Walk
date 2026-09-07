import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class AddressLocationPickerScreen extends StatefulWidget {
  const AddressLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<AddressLocationPickerScreen> createState() =>
      _AddressLocationPickerScreenState();
}

class _AddressLocationPickerScreenState
    extends State<AddressLocationPickerScreen> {
  final MapController _mapController = MapController();

  // geocoding 5.0.0 uses the Geocoding class instance.
  final geocoding.Geocoding _geocoding =
      geocoding.Geocoding();

  Timer? _geocodeDebounce;

  LatLng? _selectedLocation;

  bool _loading = true;
  bool _saving = false;
  bool _movingMap = false;

  String _selectedAddress =
      'Move the map to choose pickup location';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      LatLng location;

      if (widget.initialLatitude != null &&
          widget.initialLongitude != null) {
        location = LatLng(
          widget.initialLatitude!,
          widget.initialLongitude!,
        );
      } else {
        location = await _getInitialLocation();
      }

      _selectedLocation = location;

      await _reverseGeocode(location);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      _selectedLocation = const LatLng(
        28.6139,
        77.2090,
      );

      setState(() {
        _loading = false;
        _selectedAddress =
            'Move the map to choose pickup location';
      });
    }
  }

  Future<LatLng> _getInitialLocation() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Fallback center only.
      // User can still move the map manually.
      return const LatLng(
        28.6139,
        77.2090,
      );
    }

    final Position position =
        await Geolocator.getCurrentPosition();

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final List<geocoding.Placemark> placemarks =
          await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        if (!mounted) return;

        setState(() {
          _selectedAddress = 'Location selected';
        });

        return;
      }

      final geocoding.Placemark place =
          placemarks.first;

      final List<String> parts = <String>[
        if (place.name != null &&
            place.name!.trim().isNotEmpty)
          place.name!.trim(),
        if (place.street != null &&
            place.street!.trim().isNotEmpty)
          place.street!.trim(),
        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty)
          place.subLocality!.trim(),
        if (place.locality != null &&
            place.locality!.trim().isNotEmpty)
          place.locality!.trim(),
        if (place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea!.trim(),
        if (place.postalCode != null &&
            place.postalCode!.trim().isNotEmpty)
          place.postalCode!.trim(),
      ].toSet().toList();

      if (!mounted) return;

      setState(() {
        _selectedAddress =
            parts.isEmpty
                ? 'Location selected'
                : parts.join(', ');
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedAddress = 'Location selected';
      });
    }
  }

  void _onMapPositionChanged(
    MapCamera camera,
    bool hasGesture,
  ) {
    if (!hasGesture || _movingMap) {
      return;
    }

    // The fixed center pin represents camera.center.
    // Therefore camera.center is the exact pickup location.
    final LatLng center = camera.center;

    _selectedLocation = center;

    if (mounted) {
      setState(() {
        _selectedAddress = 'Finding address...';
      });
    }

    _geocodeDebounce?.cancel();

    _geocodeDebounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _reverseGeocode(center);
      },
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required for current location.',
            ),
          ),
        );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition();

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      _selectedLocation = location;

      if (mounted) {
        setState(() {
          _movingMap = true;
          _selectedAddress = 'Finding address...';
        });
      }

      _mapController.move(
        location,
        17,
      );

      await _reverseGeocode(location);

      if (!mounted) return;

      setState(() {
        _movingMap = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _movingMap = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get current location: $e',
          ),
        ),
      );
    }
  }

  Future<void> _useSelectedLocation() async {
    final LatLng? location = _selectedLocation;

    if (location == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    // Final coordinates are exactly the center-pin coordinates.
    await _reverseGeocode(location);

    if (!mounted) return;

    Navigator.pop(
      context,
      <String, dynamic>{
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': _selectedAddress,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _selectedLocation == null) {
      return const Scaffold(
        backgroundColor:
            DojoWalkColors.background,
        appBar: AppBar(
          backgroundColor:
              DojoWalkColors.background,
          elevation: 0,
          title: Text(
            'Choose Pickup Location',
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: DojoWalkColors.primary,
          ),
        ),
      );
    }

    final LatLng center = _selectedLocation!;

    return Scaffold(
      backgroundColor:
          DojoWalkColors.background,
      appBar: AppBar(
        backgroundColor:
            DojoWalkColors.background,
        elevation: 0,
        foregroundColor:
            DojoWalkColors.black,
        title: const Text(
          'Choose Pickup Location',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 17,
              onPositionChanged:
                  _onMapPositionChanged,
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.doojowalker.app',
              ),
            ],
          ),

          // FIXED CENTER PIN.
          // The map center underneath this pin
          // is the exact pickup point.
          const Center(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 38,
              ),
              child: Icon(
                Icons.location_pin,
                size: 52,
                color: DojoWalkColors.primary,
              ),
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius:
                  BorderRadius.circular(18),
              color: DojoWalkColors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: DojoWalkColors.primary
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color:
                            DojoWalkColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedAddress,
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color:
                                  DojoWalkColors
                                      .textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Convenience only.
          // Moves map to current GPS.
          // User can still move the map afterward.
          Positioned(
            right: 16,
            bottom: 125,
            child: FloatingActionButton(
              heroTag:
                  'address_current_location',
              onPressed:
                  _goToCurrentLocation,
              backgroundColor:
                  DojoWalkColors.white,
              foregroundColor:
                  DojoWalkColors.primary,
              elevation: 5,
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : _useSelectedLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      DojoWalkColors.primary,
                  foregroundColor:
                      DojoWalkColors.white,
                  disabledBackgroundColor:
                      DojoWalkColors.primary
                          .withValues(
                    alpha: 0.5,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              DojoWalkColors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons
                                .check_circle_outline,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Use This Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
