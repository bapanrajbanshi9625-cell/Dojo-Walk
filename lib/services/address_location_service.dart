import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

class AddressLocationResult {
  final String addressLine1;
  final String area;
  final String city;
  final String state;
  final String pincode;

  const AddressLocationResult({
    required this.addressLine1,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
  });
}

class AddressLocationService {
  AddressLocationService();

  // ==========================================================
  // GEOCODING
  // ==========================================================

  final geocoding.Geocoding _geocoding =
      geocoding.Geocoding();

  // ==========================================================
  // GET CURRENT ADDRESS
  // ==========================================================

  Future<AddressLocationResult> getCurrentAddress() async {
    // ========================================================
    // 1. CHECK LOCATION SERVICE
    // ========================================================

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // ========================================================
    // 2. CHECK / REQUEST PERMISSION
    // ========================================================

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    // ========================================================
    // 3. GET CURRENT GPS LOCATION
    //
    // geolocator ^12 compatible
    // ========================================================

    final Position position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // ========================================================
    // 4. REVERSE GEOCODING
    //
    // IMPORTANT:
    // Use Geocoding instance instead of calling
    // placemarkFromCoordinates() directly.
    // ========================================================

    final List<geocoding.Placemark> placemarks =
        await _geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // ========================================================
    // 5. ADDRESS NOT FOUND
    // ========================================================

    if (placemarks.isEmpty) {
      throw const AddressNotFoundException();
    }

    // ========================================================
    // 6. FIRST RESULT
    // ========================================================

    final geocoding.Placemark place =
        placemarks.first;

    // ========================================================
    // 7. ADDRESS COMPONENTS
    // ========================================================

    final String street =
        place.street?.trim() ?? '';

    final String subLocality =
        place.subLocality?.trim() ?? '';

    final String locality =
        place.locality?.trim() ?? '';

    final String administrativeArea =
        place.administrativeArea?.trim() ?? '';

    final String postalCode =
        place.postalCode?.trim() ?? '';

    final String subAdministrativeArea =
        place.subAdministrativeArea?.trim() ?? '';

    // ========================================================
    // 8. AREA
    // ========================================================

    String area = '';

    if (subLocality.isNotEmpty) {
      area = subLocality;
    } else if (locality.isNotEmpty) {
      area = locality;
    }

    // ========================================================
    // 9. CITY
    // ========================================================

    String city = '';

    if (locality.isNotEmpty) {
      city = locality;
    } else if (subAdministrativeArea.isNotEmpty) {
      city = subAdministrativeArea;
    }

    // ========================================================
    // 10. STATE
    // ========================================================

    final String state =
        administrativeArea;

    // ========================================================
    // 11. RETURN RESULT
    // ========================================================

    return AddressLocationResult(
      addressLine1: street,
      area: area,
      city: city,
      state: state,
      pincode: postalCode,
    );
  }

  // ==========================================================
  // OPEN LOCATION SETTINGS
  // ==========================================================

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ==========================================================
  // OPEN APP SETTINGS
  // ==========================================================

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// ============================================================
// CUSTOM EXCEPTIONS
// ============================================================

class LocationPermissionDeniedException
    implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionDeniedForeverException
    implements Exception {
  const LocationPermissionDeniedForeverException();
}

class AddressNotFoundException
    implements Exception {
  const AddressNotFoundException();
}
