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

  LatLng? _selectedLocation;

  bool _loading = true;
  bool _saving = false;
  bool _movingMap = false;

  String _selectedAddress = 'Move the map to select a location';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // ============================================================
  // INITIAL LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    try {
      // If AddressScreen already has a selected location,
      // ALWAYS start from that location.
      if (widget.initialLocation != null) {
        _selectedLocation = widget.initialLocation;

        await _reverseGeocode(widget.initialLocation!);

        if (!mounted) {
          return;
        }

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

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      _selectedLocation = location;

      await _reverseGeocode(location);

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      debugPrint(
        'Address location picker error: $e',
      );

      if (!mounted) {
        return;
      }

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
        if (mounted) {
          setState(() {
            _selectedAddress = 'Location selected';
          });
        }

        return;
      }

      final geocoding.Placemark place =
          places.first;

      final List<String> parts = <String>[];

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

      if (pincode.isNotEmpty &&
          !parts.contains(pincode)) {
        parts.add(pincode);
      }

      final String address = parts.isEmpty
          ? 'Location selected'
          : parts.join(', ');

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAddress = address;
      });
    } catch (e) {
      debugPrint(
        'Reverse geocoding failed: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedAddress = 'Location selected';
      });
    }
  }

  // ============================================================
  // MAP MOVED
  // ============================================================

  Future<void> _onMapPositionChanged(
    MapCamera camera,
    bool hasGesture,
  ) async {
    if (!hasGesture || _saving) {
      return;
    }

    final LatLng center = camera.center;

    if (!mounted) {
      return;
    }

    setState(() {
      _movingMap = true;
      _selectedLocation = center;
      _selectedAddress = 'Finding address...';
    });

    await _reverseGeocode(center);

    if (!mounted) {
      return;
    }

    setState(() {
      _movingMap = false;
    });
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    if (_saving) {
      return;
    }

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

      if (!mounted) {
        return;
      }

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

      if (!mounted) {
        return;
      }

      setState(() {
        _movingMap = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _movingMap = false;
      });

      _showError(
        _locationErrorMessage(e),
      );
    }
  }

  // ============================================================
  // USE SELECTED LOCATION
  // ============================================================

  Future<void> _useSelectedLocation() async {
    final LatLng? location = _selectedLocation;

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
      // Re-check the selected coordinates only.
      // NEVER fetch current GPS here.
      await _reverseGeocode(location);

      if (!mounted) {
        return;
      }

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
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Select Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Stack(
              children: [
                // ==================================================
                // MAP
                // ==================================================

                Positioned.fill(
                  child: _selectedLocation == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              24,
                            ),
                            child: Text(
                              'Unable to load location',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _selectedLocation!,
                            initialZoom: 17,
                            minZoom: 5,
                            maxZoom: 19,
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
                // CENTER PIN
                // ==================================================

                if (_selectedLocation != null)
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 38,
                        ),
                        child: Icon(
                          Icons.location_pin,
                          size: 50,
                          color: AppColors.primary,
                          shadows: const [
                            Shadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // SELECTED ADDRESS CARD
                // ==================================================

                Positioned(
                  left: 16,
                  right: 16,
                  top: 14,
                  child: Material(
                    color: Colors.transparent,
                    elevation: 5,
                    borderRadius:
                        BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 68,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(
                                alpha: 0.10,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _movingMap
                                      ? 'Selecting location'
                                      : 'Selected location',
                                  style: TextStyle(
                                    color: AppColors.slate,
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    height: 1.3,
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
                  bottom: 96,
                  child: SafeArea(
                    top: false,
                    left: false,
                    child: Material(
                      elevation: 5,
                      color: AppColors.card,
                      shape: const CircleBorder(),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: IconButton(
                          tooltip: 'Use current location',
                          onPressed: _saving
                              ? null
                              : _goToCurrentLocation,
                          icon: Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // BOTTOM ACTION
                // ==================================================

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saving
                            ? null
                            : _useSelectedLocation,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_rounded,
                                size: 21,
                              ),
                        label: Text(
                          _saving
                              ? 'Saving...'
                              : 'Use This Location',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor:
                              AppColors.white,
                          disabledBackgroundColor:
                              AppColors.primary
                                  .withValues(
                            alpha: 0.55,
                          ),
                          disabledForegroundColor:
                              AppColors.white,
                          elevation: 4,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
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
