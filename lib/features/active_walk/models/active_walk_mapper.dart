import 'package:cloud_firestore/cloud_firestore.dart';

import 'active_walk.dart';

class ActiveWalkMapper {
  const ActiveWalkMapper._();

  // ==========================================================
  // FROM FIRESTORE DOCUMENT
  // ==========================================================

  static ActiveWalk fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return ActiveWalk(
      id: document.id,

      // ------------------------------------------------------
      // OWNER
      // ------------------------------------------------------

      ownerId: _string(data['ownerId']),
      ownerName: _string(data['ownerName']),

      // ------------------------------------------------------
      // WALKER
      // ------------------------------------------------------

      walkerId: _string(data['walkerId']),
      walkerUid: _string(data['walkerUid']),
      walkerName: _string(data['walkerName']),
      walkerPhone: _string(data['walkerPhone']),

      // ------------------------------------------------------
      // DOG
      // ------------------------------------------------------

      dogName: _dogName(data),
      dogBreed: _dogBreed(data),

      // ------------------------------------------------------
      // STATUS
      // ------------------------------------------------------

      status: _status(data),

      // ------------------------------------------------------
      // LOCATIONS
      //
      // active_walks:
      // walkerLocation     -> Walker current location
      // ownerLocation      -> Owner/destination location
      //
      // destinationLocation is kept as fallback because
      // it already exists in your Firebase structure.
      // ------------------------------------------------------

      walkerLocation: _geoPoint(
        data['walkerLocation'],
      ),

      ownerLocation: _geoPoint(
        data['ownerLocation'] ??
            data['destinationLocation'],
      ),

      // ------------------------------------------------------
      // ADDRESS
      // ------------------------------------------------------

      address: _address(data),

      // ------------------------------------------------------
      // TIMESTAMPS
      // ------------------------------------------------------

      startedAt: _date(
        data['startedAt'],
      ),

      createdAt: _date(
        data['createdAt'],
      ),
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
    final String dogBreed =
        _string(data['dogBreed']);

    if (dogBreed.isNotEmpty) {
      return dogBreed;
    }

    final String breed =
        _string(data['breed']);

    if (breed.isNotEmpty) {
      return breed;
    }

    return 'Breed not available';
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  static String _status(
    Map<String, dynamic> data,
  ) {
    String status =
        _string(data['status']).toLowerCase();

    if (status.isEmpty) {
      return 'active';
    }

    // --------------------------------------------------------
    // Firebase may contain:
    //
    // "On that way "
    // "On The Way"
    // "on_the_way"
    // "on-the-way"
    //
    // Normalize all of them to:
    //
    // "on_the_way"
    // --------------------------------------------------------

    status = status
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    while (status.contains('__')) {
      status = status.replaceAll(
        '__',
        '_',
      );
    }

    if (status == 'on_that_way' ||
        status == 'on_the_way') {
      return 'on_the_way';
    }

    if (status == 'accepted') {
      return 'accepted';
    }

    if (status == 'active') {
      return 'active';
    }

    if (status == 'reached') {
      return 'reached';
    }

    if (status == 'walking' ||
        status == 'in_progress') {
      return status;
    }

    if (status == 'completed') {
      return 'completed';
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

    final String destinationAddress =
        _string(data['destinationAddress']);

    if (destinationAddress.isNotEmpty) {
      return destinationAddress;
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
          value['latitude'] ??
              value['lat'];

      final dynamic longitude =
          value['longitude'] ??
              value['lng'];

      final double? lat =
          double.tryParse(
        latitude?.toString() ?? '',
      );

      final double? lng =
          double.tryParse(
        longitude?.toString() ?? '',
      );

      if (lat != null &&
          lng != null) {
        return GeoPoint(
          lat,
          lng,
        );
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
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }
}
