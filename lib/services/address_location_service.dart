import 'package:geocoding/geocoding.dart' as geocoding;

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

  final geocoding.Geocoding _geocoding =
      geocoding.Geocoding();

  Future<AddressLocationResult> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final List<geocoding.Placemark> placemarks =
        await _geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isEmpty) {
      throw const AddressNotFoundException();
    }

    final geocoding.Placemark place =
        placemarks.first;

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

    String area = '';

    if (subLocality.isNotEmpty) {
      area = subLocality;
    } else if (locality.isNotEmpty) {
      area = locality;
    }

    String city = '';

    if (locality.isNotEmpty) {
      city = locality;
    } else if (subAdministrativeArea.isNotEmpty) {
      city = subAdministrativeArea;
    }

    return AddressLocationResult(
      addressLine1: street,
      area: area,
      city: city,
      state: administrativeArea,
      pincode: postalCode,
    );
  }
}

class AddressNotFoundException implements Exception {
  const AddressNotFoundException();
}
