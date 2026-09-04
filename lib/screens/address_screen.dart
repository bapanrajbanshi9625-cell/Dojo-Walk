import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_colors.dart';
import '../services/address_location_service.dart';
import '../widgets/address_screen_widgets.dart';
import 'address_location_picker_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({
    super.key,
    this.fromProfile = false,
  });

  final bool fromProfile;

  @override
  State<AddressScreen> createState() =>
      _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final AddressLocationService _locationService =
      AddressLocationService();

  final TextEditingController _flatController =
      TextEditingController();

  final TextEditingController _addressLine1Controller =
      TextEditingController();

  final TextEditingController _addressLine2Controller =
      TextEditingController();

  final TextEditingController _areaController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  DocumentReference<Map<String, dynamic>>?
      _ownerProfileRef;

  final List<Map<String, dynamic>> _savedAddresses =
      <Map<String, dynamic>>[];

  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // ============================================================
  // FIND OWNER
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?>
      _findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>>
        querySnapshot = await _firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.reference;
    }

    final DocumentReference<Map<String, dynamic>>
        uidReference = _firestore
            .collection('owners')
            .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>>
        uidSnapshot = await uidReference.get();

    if (uidSnapshot.exists) {
      return uidReference;
    }

    return null;
  }

  // ============================================================
  // LOAD ADDRESS
  // ============================================================

  Future<void> _loadAddress() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      DocumentReference<Map<String, dynamic>>?
          ownerRef = await _findOwnerProfile();

      ownerRef ??=
          _firestore.collection('owners').doc(user.uid);

      _ownerProfileRef = ownerRef;

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        final dynamic rawAddress =
            data['address'];

        if (rawAddress is Map) {
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(rawAddress);

          _flatController.text =
              _readString(address['flatNumber']);

          _addressLine1Controller.text =
              _readString(address['addressLine1']);

          _addressLine2Controller.text =
              _readString(address['addressLine2']);

          _areaController.text =
              _readString(address['area']);

          _cityController.text =
              _readString(address['city']);

          _stateController.text =
              _readString(address['state']);

          _pinCodeController.text =
              _readString(address['pincode']);

          _selectedLatitude =
              _readDouble(address['latitude']);

          _selectedLongitude =
              _readDouble(address['longitude']);
        }

        final dynamic saved =
            data['savedAddresses'];

        _savedAddresses.clear();

        if (saved is List) {
          for (final dynamic item in saved) {
            if (item is Map) {
              _savedAddresses.add(
                Map<String, dynamic>.from(item),
              );
            }
          }
        }

        if (_savedAddresses.isEmpty &&
            rawAddress is Map) {
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(rawAddress);

          final String fullAddress =
              _buildFullAddress();

          if (fullAddress.isNotEmpty) {
            _savedAddresses.add(
              <String, dynamic>{
                'address': fullAddress,
                'flatNumber':
                    _readString(
                  address['flatNumber'],
                ),
                'addressLine1':
                    _readString(
                  address['addressLine1'],
                ),
                'addressLine2':
                    _readString(
                  address['addressLine2'],
                ),
                'area':
                    _readString(
                  address['area'],
                ),
                'city':
                    _readString(
                  address['city'],
                ),
                'state':
                    _readString(
                  address['state'],
                ),
                'pincode':
                    _readString(
                  address['pincode'],
                ),
                'latitude':
                    _readDouble(
                  address['latitude'],
                ),
                'longitude':
                    _readDouble(
                  address['longitude'],
                ),
              },
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to load address: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation || _saving) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Location is Off',
              ),
              content: const Text(
                'Please turn on location services to '
                'use your current location.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    await _locationService
                        .openLocationSettings();
                  },
                  child: const Text(
                    'Open Settings',
                  ),
                ),
              ],
            );
          },
        );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw const LocationPermissionDeniedForeverException();
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      final double latitude =
          position.latitude;

      final double longitude =
          position.longitude;

      _selectedLatitude = latitude;
      _selectedLongitude = longitude;

      final AddressLocationResult result =
          await _locationService.getCurrentAddress();

      if (!mounted) {
        return;
      }

      _addressLine1Controller.text =
          result.addressLine1;

      _areaController.text =
          result.area;

      _cityController.text =
          result.city;

      _stateController.text =
          result.state;

      _pinCodeController.text =
          result.pincode;

      setState(() {});
    } on LocationPermissionDeniedException {
      if (!mounted) return;

      _showMessage(
        'Location permission is required.',
      );
    } on LocationPermissionDeniedForeverException {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Location Permission',
            ),
            content: const Text(
              'Location permission is permanently denied. '
              'Please enable it from app settings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  await _locationService
                      .openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                ),
              ),
            ],
          );
        },
      );
    } on LocationServiceDisabledException {
      if (!mounted) return;

      _showMessage(
        'Please turn on location services.',
      );
    } on AddressNotFoundException {
      if (!mounted) return;

      _showMessage(
        'Unable to find an address for this location.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to get current location: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // SELECTED MAP LOCATION -> ADDRESS FIELDS
  // ============================================================

  Future<void> _populateAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final geocoding.Geocoding geocoder =
          geocoding.Geocoding();

      final List<geocoding.Placemark> places =
          await geocoder.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (places.isEmpty) {
        return;
      }

      final geocoding.Placemark place =
          places.first;

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

      if (!mounted) {
        return;
      }

      if (street.isNotEmpty) {
        _addressLine1Controller.text =
            street;
      }

      if (area.isNotEmpty) {
        _areaController.text = area;
      }

      if (city.isNotEmpty) {
        _cityController.text = city;
      }

      if (state.isNotEmpty) {
        _stateController.text = state;
      }

      if (pincode.isNotEmpty) {
        _pinCodeController.text = pincode;
      }
    } catch (e) {
      debugPrint(
        'Selected coordinate reverse geocoding failed: $e',
      );
    }
  }

  // ============================================================
  // BUILD FULL ADDRESS
  // ============================================================

  String _buildFullAddress() {
    final List<String> parts =
        <String>[];

    void add(String value) {
      final String trimmed =
          value.trim();

      if (trimmed.isNotEmpty) {
        parts.add(trimmed);
      }
    }

    add(_flatController.text);
    add(_addressLine1Controller.text);
    add(_addressLine2Controller.text);
    add(_areaController.text);
    add(_cityController.text);
    add(_stateController.text);
    add(_pinCodeController.text);

    return parts.join(', ');
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<void> _saveAddress() async {
    if (_saving) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
      );
      return;
    }

    final String flat =
        _flatController.text.trim();

    final String line1 =
        _addressLine1Controller.text.trim();

    final String line2 =
        _addressLine2Controller.text.trim();

    final String area =
        _areaController.text.trim();

    final String city =
        _cityController.text.trim();

    final String state =
        _stateController.text.trim();

    final String pin =
        _pinCodeController.text.trim();

    if (line1.isEmpty ||
        area.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        pin.isEmpty) {
      _showMessage(
        'Please fill all required address fields.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerProfileRef;

      ownerRef ??=
          await _findOwnerProfile();

      ownerRef ??=
          _firestore
              .collection('owners')
              .doc(user.uid);

      _ownerProfileRef = ownerRef;

      final String fullAddress =
          _buildFullAddress();

      final Map<String, dynamic>
          savedAddress =
          <String, dynamic>{
        'address': fullAddress,
        'flatNumber': flat,
        'addressLine1': line1,
        'addressLine2': line2,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pin,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
      };

      final List<Map<String, dynamic>>
          addresses =
          <Map<String, dynamic>>[
        savedAddress,
      ];

      final Map<String, dynamic>
          address =
          <String, dynamic>{
        'flatNumber': flat,
        'addressLine1': line1,
        'addressLine2': line2,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pin,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
      };

      await ownerRef.set(
        <String, dynamic>{
          'authUid': user.uid,
          'address': address,
          'savedAddresses': addresses,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses
          ..clear()
          ..add(savedAddress);
      });

      _showMessage(
        'Address saved successfully.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to save address: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // SELECT SAVED ADDRESS
  // ============================================================

  void _selectAddress(
    Map<String, dynamic> address,
  ) {
    _flatController.text =
        _readString(
      address['flatNumber'],
    );

    _addressLine1Controller.text =
        _readString(
      address['addressLine1'],
    );

    _addressLine2Controller.text =
        _readString(
      address['addressLine2'],
    );

    _areaController.text =
        _readString(
      address['area'],
    );

    _cityController.text =
        _readString(
      address['city'],
    );

    _stateController.text =
        _readString(
      address['state'],
    );

    _pinCodeController.text =
        _readString(
      address['pincode'],
    );

    _selectedLatitude =
        _readDouble(
      address['latitude'],
    );

    _selectedLongitude =
        _readDouble(
      address['longitude'],
    );

    setState(() {});
  }

  // ============================================================
  // EDIT SAVED ADDRESS
  // ============================================================

  Future<void> _editAddress(
    int index,
  ) async {
    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final Map<String, dynamic>
        address =
        _savedAddresses[index];

    _selectAddress(address);

    await Future<void>.delayed(
      const Duration(
        milliseconds: 100,
      ),
    );

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context)
                    .viewInsets
                    .bottom,
          ),
          child: Container(
            constraints:
                BoxConstraints(
              maxHeight:
                  MediaQuery.of(context)
                      .size
                      .height *
                      0.88,
            ),
            padding:
                const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin:
                        const EdgeInsets.only(
                      bottom: 18,
                    ),
                    decoration:
                        BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  AddressScreenWidgets
                      .sectionTitle(
                    'Edit Address',
                    'Update your saved address',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _flatController,
                    label:
                        'Flat / House No.',
                    hint:
                        'Enter flat or house number',
                    icon:
                        Icons.home_outlined,
                    requiredField: false,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _addressLine1Controller,
                    label:
                        'Address Line 1',
                    hint:
                        'Street / building / road',
                    icon:
                        Icons.location_on_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _addressLine2Controller,
                    label:
                        'Address Line 2',
                    hint: 'Optional',
                    icon: Icons
                        .add_location_alt_outlined,
                    requiredField: false,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _areaController,
                    label: 'Area',
                    hint: 'Enter area',
                    icon:
                        Icons.place_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _cityController,
                    label: 'City',
                    hint: 'Enter city',
                    icon: Icons
                        .location_city_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _stateController,
                    label: 'State',
                    hint: 'Enter state',
                    icon:
                        Icons.map_outlined,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  AddressScreenWidgets.field(
                    controller:
                        _pinCodeController,
                    label: 'PIN Code',
                    hint: 'Enter PIN code',
                    icon:
                        Icons.pin_drop_outlined,
                    keyboardType:
                        TextInputType.number,
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(
                          context,
                        );

                        await _saveAddress();
                      },
                      child:
                          const Text(
                        'Update Address',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE SAVED ADDRESS
  // ============================================================

  Future<void> _deleteAddress(
    int index,
  ) async {
    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          title: const Text(
            'Delete Address?',
          ),
          content: const Text(
            'Are you sure you want to delete this address?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        return;
      }

      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerProfileRef;

      ownerRef ??=
          await _findOwnerProfile();

      ownerRef ??=
          _firestore
              .collection('owners')
              .doc(user.uid);

      final List<Map<String, dynamic>>
          addresses =
          List<Map<String, dynamic>>.from(
        _savedAddresses,
      );

      addresses.removeAt(index);

      final Map<String, dynamic>
          updateData =
          <String, dynamic>{
        'savedAddresses': addresses,
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      if (addresses.isEmpty) {
        updateData['address'] =
            FieldValue.delete();
      }

      await ownerRef.set(
        updateData,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);
      });

      _showMessage(
        'Address deleted.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to delete address: $e',
      );
    }
  }

  // ============================================================
  // OPEN LOCATION PICKER
  // ============================================================

  Future<void> _openLocationPicker() async {
    if (_saving) {
      return;
    }

    final Map<String, dynamic>? result =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (BuildContext context) {
          return AddressLocationPickerScreen(
            initialLocation:
                _selectedLatitude != null &&
                        _selectedLongitude != null
                    ? LatLng(
                        _selectedLatitude!,
                        _selectedLongitude!,
                      )
                    : null,
          );
        },
      ),
    );

    if (result == null) {
      return;
    }

    final double? latitude =
        _readDouble(
      result['latitude'],
    );

    final double? longitude =
        _readDouble(
      result['longitude'],
    );

    if (latitude == null ||
        longitude == null) {
      return;
    }

    // ==========================================================
    // IMPORTANT:
    // Keep EXACTLY the location selected on the map.
    // Do NOT call getCurrentAddress() here.
    // ==========================================================

    _selectedLatitude = latitude;
    _selectedLongitude = longitude;

    await _populateAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );

    // If reverse geocoding returned nothing,
    // still keep the selected map address as a fallback.
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

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
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  double? _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _flatController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
            AppColors.background,
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.navy,
        titleSpacing: 16,
        title: const Text(
          'Address',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
          padding:
              const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              AddressScreenWidgets
                  .bookingHeader(),

              const SizedBox(
                height: 18,
              ),

              AddressScreenWidgets
                  .currentLocationCard(
                gettingLocation:
                    _gettingLocation,
                disabled: _saving,
                onTap:
                    _useCurrentLocation,
              ),

              const SizedBox(
                height: 26,
              ),

              AddressScreenWidgets
                  .sectionTitle(
                'Your Address',
                'Enter the address where your dog will be picked up',
              ),

              const SizedBox(
                height: 16,
              ),

              AddressScreenWidgets.field(
                controller:
                    _flatController,
                label:
                    'Flat / House No.',
                hint:
                    'Enter flat or house number',
                icon:
                    Icons.home_outlined,
                requiredField: false,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _addressLine1Controller,
                label:
                    'Address Line 1',
                hint:
                    'Street / building / road',
                icon:
                    Icons.location_on_outlined,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _addressLine2Controller,
                label:
                    'Address Line 2',
                hint: 'Optional',
                icon: Icons
                    .add_location_alt_outlined,
                requiredField: false,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _areaController,
                label: 'Area',
                hint: 'Enter area',
                icon:
                    Icons.place_outlined,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _cityController,
                label: 'City',
                hint: 'Enter city',
                icon: Icons
                    .location_city_outlined,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _stateController,
                label: 'State',
                hint: 'Enter state',
                icon:
                    Icons.map_outlined,
              ),

              const SizedBox(
                height: 12,
              ),

              AddressScreenWidgets.field(
                controller:
                    _pinCodeController,
                label: 'PIN Code',
                hint: 'Enter PIN code',
                icon:
                    Icons.pin_drop_outlined,
                keyboardType:
                    TextInputType.number,
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // MAP LOCATION
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.card,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.border,
                    width: 0.7,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
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
                          child:
                              Icon(
                            Icons
                                .map_outlined,
                            color:
                                AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          width: 11,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Choose on Map',
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.navy,
                                  fontSize:
                                      14,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              const SizedBox(
                                height: 2,
                              ),
                              Text(
                                _selectedLatitude !=
                                            null &&
                                        _selectedLongitude !=
                                            null
                                    ? 'Location selected'
                                    : 'Pinpoint your pickup location',
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.slate,
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 13,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 50,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            _saving
                                ? null
                                : _openLocationPicker,
                        icon:
                            const Icon(
                          Icons
                              .location_on_outlined,
                          size: 20,
                        ),
                        label:
                            const Text(
                          'Choose Location on Map',
                          style:
                              TextStyle(
                            fontSize:
                                13,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    if (_selectedLatitude !=
                            null &&
                        _selectedLongitude !=
                            null) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .check_circle_rounded,
                            color:
                                AppColors.primary,
                            size: 17,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              'Map location saved for this address',
                              style:
                                  TextStyle(
                                color:
                                    AppColors.slate,
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // SAVED ADDRESSES
              // ==================================================

              if (_savedAddresses
                  .isNotEmpty) ...[
                AddressScreenWidgets
                    .sectionTitle(
                  'Saved Addresses',
                  'Select or manage your saved address',
                ),

                const SizedBox(
                  height: 14,
                ),

                ...List.generate(
                  _savedAddresses.length,
                  (int index) {
                    final Map<String,
                            dynamic>
                        address =
                        _savedAddresses[
                            index];

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child:
                          AddressScreenWidgets
                              .savedAddressCard(
                        index: index,
                        address: address,
                        onSelect: () {
                          _selectAddress(
                            address,
                          );
                        },
                        onEdit: () {
                          _editAddress(
                            index,
                          );
                        },
                        onDelete: () {
                          _deleteAddress(
                            index,
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(
                  height: 12,
                ),
              ],

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _saving
                          ? null
                          : _saveAddress,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style:
                              TextStyle(
                            fontSize:
                                14,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
