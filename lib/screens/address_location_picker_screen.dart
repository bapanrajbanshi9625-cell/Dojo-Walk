import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_colors.dart';

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

  String _selectedAddress = 'Move the map to select location';

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

  // ============================================================
  // INITIAL LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLocation != null) {
        _selectedLocation = widget.initialLocation;

        await _reverseGeocode(
          widget.initialLocation!,
        );

        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _PickerPermissionException();
      }

      if (permission == LocationPermission.deniedForever) {
        throw const _PickerPermissionForeverException();
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      await _reverseGeocode(
        _selectedLocation!,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Address location picker error: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError(
        _locationErrorMessage(e),
      );
    }
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<void> _reverseGeocode(
    LatLng location,
  ) async {
    try {
      final geocoding.Geocoding geocoder =
          geocoding.Geocoding();

      final List<geocoding.Placemark> places =
          await geocoder.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (places.isEmpty) {
        if (!mounted) return;

        setState(() {
          _selectedAddress = 'Location selected';
        });

        return;
      }

      final geocoding.Placemark place =
          places.first;

      final List<String> parts = [];

      final String street =
          place.street?.trim() ?? '';

      final String area =
          place.subLocality?.trim() ?? '';

      final String city =
          place.locality?.trim() ?? '';

      final String state =
          place.administrativeArea?.trim() ?? '';

      final String pincode =
          place.postalCode?.trim() ?? '';

      if (street.isNotEmpty) {
        parts.add(street);
      }

      if (area.isNotEmpty &&
          !parts.contains(area)) {
        parts.add(area);
      }

      if (city.isNotEmpty &&
          !parts.contains(city)) {
        parts.add(city);
      }

      if (state.isNotEmpty &&
          !parts.contains(state)) {
        parts.add(state);
      }

      if (pincode.isNotEmpty) {
        parts.add(pincode);
      }

      final String address = parts.isEmpty
          ? 'Location selected'
          : parts.join(', ');

      if (!mounted) return;

      setState(() {
        _selectedAddress = address;
      });
    } catch (e) {
      debugPrint(
        'Reverse geocoding failed: $e',
      );

      if (!mounted) return;

      setState(() {
        _selectedAddress = 'Location selected';
      });
    }
  }

  // ============================================================
  // MAP MOVED
  // ============================================================

  void _onMapPositionChanged(
    MapCamera camera,
    bool hasGesture,
  ) {
    if (!hasGesture || _saving) {
      return;
    }

    final LatLng center = camera.center;

    setState(() {
      _movingMap = true;
      _selectedLocation = center;
      _selectedAddress = 'Finding address...';
    });

    _geocodeDebounce?.cancel();

    _geocodeDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        await _reverseGeocode(center);

        if (!mounted) return;

        setState(() {
          _movingMap = false;
        });
      },
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    if (_saving) return;

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw const LocationServiceDisabledException();
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _PickerPermissionException();
      }

      if (permission == LocationPermission.deniedForever) {
        throw const _PickerPermissionForeverException();
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      _geocodeDebounce?.cancel();

      if (!mounted) return;

      setState(() {
        _selectedLocation = location;
        _selectedAddress = 'Finding address...';
        _movingMap = true;
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

      _showError(
        _locationErrorMessage(e),
      );
    }
  }

  // ============================================================
  // USE SELECTED LOCATION
  // ============================================================

  Future<void> _useSelectedLocation() async {
    final LatLng? location =
        _selectedLocation;

    if (location == null) {
      _showError(
        'Please select a location first.',
      );
      return;
    }

    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Re-confirm address for EXACT selected coordinates.
      await _reverseGeocode(location);

      if (!mounted) return;

      Navigator.of(context).pop(
        <String, dynamic>{
          'latitude': location.latitude,
          'longitude': location.longitude,
          'address': _selectedAddress,
        },
      );
    } catch (e) {
      debugPrint(
        'Location save error: $e',
      );

      if (mounted) {
        _showError(
          'Unable to select this location.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _locationErrorMessage(
    Object error,
  ) {
    if (error
        is LocationServiceDisabledException) {
      return 'Please turn on Location/GPS.';
    }

    if (error
        is _PickerPermissionException) {
      return 'Location permission is required.';
    }

    if (error
        is _PickerPermissionForeverException) {
      return 'Location permission is permanently denied. Please allow it from App Settings.';
    }

    return 'Unable to detect your location.';
  }

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.navy,
        foregroundColor:
            AppColors.white,
        elevation: 0,
        title: const Text(
          'Select Location',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      body: _loading
          ? Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            )
          : Stack(
              children: [
                // ==================================================
                // MAP
                // ==================================================

                Positioned.fill(
                  child:
                      _selectedLocation == null
                          ? Center(
                              child: Text(
                                'Unable to load location',
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.slate,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            )
                          : FlutterMap(
                              mapController:
                                  _mapController,
                              options:
                                  MapOptions(
                                initialCenter:
                                    _selectedLocation!,
                                initialZoom:
                                    17,
                                onPositionChanged:
                                    _onMapPositionChanged,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.doojowalker.app',
                                ),
                              ],
                            ),
                ),

                // ==================================================
                // FIXED CENTER PIN
                // ==================================================

                if (_selectedLocation !=
                    null)
                  Center(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 38,
                      ),
                      child: Icon(
                        Icons.location_pin,
                        size: 52,
                        color:
                            AppColors.primary,
                        shadows: const [
                          Shadow(
                            blurRadius: 5,
                            offset:
                                Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // ADDRESS CARD
                // ==================================================

                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Material(
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    child: Container(
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.card,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                BoxDecoration(
                              color: AppColors
                                  .primary
                                  .withValues(
                                alpha: 0.10,
                              ),
                              shape:
                                  BoxShape.circle,
                            ),
                            child: Icon(
                              Icons
                                  .location_on_rounded,
                              color:
                                  AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  _movingMap
                                      ? 'Selecting location'
                                      : 'Selected location',
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.slate,
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  _selectedAddress,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      TextStyle(
                                    color:
                                        AppColors.navy,
                                    fontSize:
                                        13,
                                    fontWeight:
                                        FontWeight.w800,
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

                // ==================================================
                // CURRENT LOCATION BUTTON
                // ==================================================

                Positioned(
                  right: 16,
                  bottom: 118,
                  child:
                      FloatingActionButton(
                    heroTag:
                        'address_current_location',
                    onPressed:
                        _goToCurrentLocation,
                    backgroundColor:
                        AppColors.card,
                    foregroundColor:
                        AppColors.primary,
                    elevation: 5,
                    child: const Icon(
                      Icons
                          .my_location_rounded,
                    ),
                  ),
                ),

                // ==================================================
                // BOTTOM ACTION
                // ==================================================

                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 54,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            _saving
                                ? null
                                : _useSelectedLocation,
                        icon: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2.2,
                                  color:
                                      AppColors.white,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .check_circle_rounded,
                              ),
                        label: Text(
                          _saving
                              ? 'Saving...'
                              : 'Use This Location',
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor:
                              AppColors.white,
                          elevation: 4,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================
// INTERNAL EXCEPTIONS
// ============================================================

class _PickerPermissionException
    implements Exception {
  const _PickerPermissionException();
}

class _PickerPermissionForeverException
    implements Exception {
  const _PickerPermissionForeverException();
}
