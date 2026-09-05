import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

class AddressLocationPickerScreen extends StatefulWidget {
  const AddressLocationPickerScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<AddressLocationPickerScreen> createState() =>
      _AddressLocationPickerScreenState();
}

class _AddressLocationPickerScreenState
    extends State<AddressLocationPickerScreen> {
  final MapController _mapController = MapController();

  Timer? _geocodeDebounce;

  LatLng? _selectedLocation;

  bool _loading = true;
  bool _saving = false;
  bool _movingMap = false;

  String _selectedAddress = 'Move the map to choose pickup location';

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

      if (widget.initialLocation != null) {
        location = widget.initialLocation!;
      } else {
        final permission = await Geolocator.checkPermission();

        LocationPermission finalPermission = permission;

        if (permission == LocationPermission.denied) {
          finalPermission = await Geolocator.requestPermission();
        }

        if (finalPermission == LocationPermission.denied ||
            finalPermission == LocationPermission.deniedForever) {
          location = const LatLng(
            28.6139,
            77.2090,
          );
        } else {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          location = LatLng(
            position.latitude,
            position.longitude,
          );
        }
      }

      _selectedLocation = location;

      await _reverseGeocode(location);

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _selectedLocation ??= const LatLng(
          28.6139,
          77.2090,
        );
        _loading = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Location selected';
          });
        }
        return;
      }

      final place = placemarks.first;

      final parts = <String>[
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ].where((value) {
        return value != null && value.trim().isNotEmpty;
      }).map((value) => value!.trim()).toSet().toList();

      if (!mounted) return;

      setState(() {
        _selectedAddress =
            parts.isEmpty ? 'Location selected' : parts.join(', ');
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

    // EXACT pickup point = exact center of the map.
    final center = camera.center;

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
      final permission = await Geolocator.checkPermission();

      LocationPermission finalPermission = permission;

      if (permission == LocationPermission.denied) {
        finalPermission = await Geolocator.requestPermission();
      }

      if (finalPermission == LocationPermission.denied ||
          finalPermission == LocationPermission.deniedForever) {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      _selectedLocation = location;

      setState(() {
        _movingMap = true;
        _selectedAddress = 'Finding address...';
      });

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
          content: Text('Unable to get current location: $e'),
        ),
      );
    }
  }

  Future<void> _useSelectedLocation() async {
    final location = _selectedLocation;

    if (location == null || _saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    // Reverse geocode the FINAL center-pin coordinates one more time.
    await _reverseGeocode(location);

    if (!mounted) return;

    Navigator.pop(
      context,
      {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': _selectedAddress,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _selectedLocation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Choose Pickup Location'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final center = _selectedLocation!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Choose Pickup Location',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 17,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.doojowalker.app',
              ),
            ],
          ),

          // Fixed center pin.
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 38),
              child: Icon(
                Icons.location_pin,
                size: 52,
                color: AppColors.primary,
              ),
            ),
          ),

          // Address information.
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _selectedAddress,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: Colors.grey.shade700,
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

          // Current location is only a convenience button.
          // It does NOT force the final pickup location.
          Positioned(
            right: 16,
            bottom: 125,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
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
                onPressed: _saving ? null : _useSelectedLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Use This Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
