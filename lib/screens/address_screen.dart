import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';

import '../core/constants/app_colors.dart';
import '../widgets/address_screen_widgets.dart';
import 'address_location_picker_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({
    super.key,
    this.fromProfile = false,
  });

  final bool fromProfile;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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

  final List<Map<String, dynamic>> _savedAddresses = [];

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

      ownerRef ??= _firestore
          .collection('owners')
          .doc(user.uid);

      _ownerProfileRef = ownerRef;

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ?? {};

        // --------------------------------------------------------
        // CANONICAL ADDRESS
        // --------------------------------------------------------

        final dynamic rawAddress = data['address'];

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

        // --------------------------------------------------------
        // SAVED ADDRESSES
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // MIGRATE CANONICAL ADDRESS TO SAVED ADDRESS
        // --------------------------------------------------------

        if (_savedAddresses.isEmpty &&
            rawAddress is Map) {
          final Map<String, dynamic> address =
              Map<String, dynamic>.from(rawAddress);

          final String fullAddress =
              _buildFullAddress();

          if (fullAddress.isNotEmpty) {
            _savedAddresses.add({
              'address': fullAddress,
              'flatNumber':
                  _readString(address['flatNumber']),
              'addressLine1':
                  _readString(address['addressLine1']),
              'addressLine2':
                  _readString(address['addressLine2']),
              'area':
                  _readString(address['area']),
              'city':
                  _readString(address['city']),
              'state':
                  _readString(address['state']),
              'pincode':
                  _readString(address['pincode']),
              'latitude':
                  _readDouble(address['latitude']),
              'longitude':
                  _readDouble(address['longitude']),
            });
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
  // PICKUP LOCATION
  // ============================================================

  Future<void> _openLocationPicker() async {
    if (_saving || _gettingLocation) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final Map<String, dynamic>? result =
          await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) {
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

      if (result == null || !mounted) {
        return;
      }

      final double? latitude =
          _readDouble(result['latitude']);

      final double? longitude =
          _readDouble(result['longitude']);

      if (latitude == null || longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a valid pickup location.',
            ),
          ),
        );
        return;
      }

      // ========================================================
      // IMPORTANT
      //
      // These are the coordinates selected on the MAP.
      // We do NOT use device current location here.
      // ========================================================

      _selectedLatitude = latitude;
      _selectedLongitude = longitude;

      // Clear old location fields so that an old address
      // cannot remain when the new selected location
      // has incomplete reverse-geocoding data.
      _addressLine1Controller.clear();
      _areaController.clear();
      _cityController.clear();
      _stateController.clear();
      _pinCodeController.clear();

      // ========================================================
      // REVERSE GEOCODE THE SELECTED MAP LOCATION
      // ========================================================

      await _fillAddressFromCoordinates(
        latitude,
        longitude,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to set pickup location: $e',
          ),
        ),
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
  // REVERSE GEOCODE SELECTED COORDINATES
  // ============================================================

  Future<void> _fillAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final List<geocoding.Placemark> places =
          await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (places.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location selected, but address details could not be found.',
              ),
            ),
          );
        }
        return;
      }

      final geocoding.Placemark place =
          places.first;

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

      final String thoroughfare =
          place.thoroughfare?.trim() ?? '';

      // --------------------------------------------------------
      // ADDRESS LINE 1
      // --------------------------------------------------------

      String addressLine1 = street;

      if (addressLine1.isEmpty) {
        addressLine1 = thoroughfare;
      }

      // --------------------------------------------------------
      // AREA
      // --------------------------------------------------------

      String area = subLocality;

      // Avoid putting the same value in both fields.
      if (area == addressLine1) {
        area = '';
      }

      // --------------------------------------------------------
      // CITY
      // --------------------------------------------------------

      String city = locality;

      if (city == area ||
          city == addressLine1) {
        city = '';
      }

      // --------------------------------------------------------
      // STATE
      // --------------------------------------------------------

      String state = administrativeArea;

      if (state == city ||
          state == area ||
          state == addressLine1) {
        state = '';
      }

      _addressLine1Controller.text =
          addressLine1;

      _areaController.text =
          area;

      _cityController.text =
          city;

      _stateController.text =
          state;

      _pinCodeController.text =
          postalCode;
    } catch (e) {
      debugPrint(
        'Selected location reverse geocoding failed: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location selected, but address details could not be loaded.',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // BUILD FULL ADDRESS
  // ============================================================

  String _buildFullAddress() {
    final List<String> parts = [];

    void add(String value) {
      final String trimmed = value.trim();

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

    final User? user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login again.',
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required address fields.',
          ),
        ),
      );
      return;
    }

    // A pickup location should have coordinates.
    if (_selectedLatitude == null ||
        _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose a pickup location on the map.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerProfileRef;

      ownerRef ??= await _findOwnerProfile();

      ownerRef ??= _firestore
          .collection('owners')
          .doc(user.uid);

      _ownerProfileRef = ownerRef;

      final String fullAddress =
          _buildFullAddress();

      // --------------------------------------------------------
      // SAVED ADDRESS
      // --------------------------------------------------------

      final Map<String, dynamic> savedAddress = {
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

      final List<Map<String, dynamic>> addresses = [
        savedAddress,
      ];

      // --------------------------------------------------------
      // CANONICAL ADDRESS
      // --------------------------------------------------------

      final Map<String, dynamic> address = {
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
        {
          'authUid': user.uid,
          'address': address,
          'savedAddresses': addresses,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..add(savedAddress);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address saved successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save address: $e',
          ),
        ),
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

    setState(() {});
  }

  // ============================================================
  // EDIT SAVED ADDRESS
  // ============================================================

  Future<void> _editAddress(int index) async {
    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final Map<String, dynamic> address =
        _savedAddresses[index];

    _selectAddress(address);

    await Future<void>.delayed(
      const Duration(milliseconds: 100),
    );

    if (!mounted) {
      return;
    }

    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AddressScreenWidgets.sectionTitle(
                      'Edit Address',
                      'Update your saved address',
                    ),

                    const SizedBox(height: 16),

                    AddressScreenWidgets.field(
                      controller:
                          _flatController,
                      label: 'Flat / House No.',
                      hint:
                          'Enter flat or house number',
                      icon:
                          Icons.home_outlined,
                      requiredField: false,
                    ),

                    const SizedBox(height: 12),

                    AddressScreenWidgets.field(
                      controller:
                          _addressLine1Controller,
                      label: 'Address Line 1',
                      hint: 'Enter address',
                      icon:
                          Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 12),

                    AddressScreenWidgets.field(
                      controller:
                          _addressLine2Controller,
                      label: 'Address Line 2',
                      hint: 'Optional',
                      icon:
                          Icons.add_location_alt_outlined,
                      requiredField: false,
                    ),

                    const SizedBox(height: 12),

                    AddressScreenWidgets.field(
                      controller:
                          _areaController,
                      label: 'Area',
                      hint: 'Enter area',
                      icon:
                          Icons.place_outlined,
                    ),

                    const SizedBox(height: 12),

                    AddressScreenWidgets.field(
                      controller:
                          _cityController,
                      label: 'City',
                      hint: 'Enter city',
                      icon:
                          Icons.location_city_outlined,
                    ),

                    const SizedBox(height: 12),

                    AddressScreenWidgets.field(
                      controller:
                          _stateController,
                      label: 'State',
                      hint: 'Enter state',
                      icon:
                          Icons.map_outlined,
                    ),

                    const SizedBox(height: 12),

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

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveAddress();
                        },
                        child: const Text(
                          'Update Address',
                        ),
                      ),
                    ),
                  ],
                ),
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

  Future<void> _deleteAddress(int index) async {
    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
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
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
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
          updateData = {
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

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Address deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete address: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  double? _readDouble(dynamic value) {
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
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
            AppColors.background,
        body: const Center(
          child:
              CircularProgressIndicator(),
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
        title: const Text(
          'Address',
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
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

              const SizedBox(height: 18),

              // ==================================================
              // PICKUP LOCATION
              // ==================================================

              AddressScreenWidgets
                  .currentLocationCard(
                gettingLocation:
                    _gettingLocation,
                disabled:
                    _saving,
                onTap:
                    _openLocationPicker,
              ),

              const SizedBox(height: 24),

              AddressScreenWidgets
                  .sectionTitle(
                'Your Address',
                'Enter the address where your dog will be picked up',
              ),

              const SizedBox(height: 16),

              AddressScreenWidgets.field(
                controller:
                    _flatController,
                label:
                    'Flat / House No.',
                hint:
                    'Enter flat or house number',
                icon:
                    Icons.home_outlined,
                requiredField:
                    false,
              ),

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller:
                    _addressLine2Controller,
                label:
                    'Address Line 2',
                hint:
                    'Optional',
                icon:
                    Icons.add_location_alt_outlined,
                requiredField:
                    false,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller:
                    _areaController,
                label:
                    'Area',
                hint:
                    'Enter area',
                icon:
                    Icons.place_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller:
                    _cityController,
                label:
                    'City',
                hint:
                    'Enter city',
                icon:
                    Icons.location_city_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller:
                    _stateController,
                label:
                    'State',
                hint:
                    'Enter state',
                icon:
                    Icons.map_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller:
                    _pinCodeController,
                label:
                    'PIN Code',
                hint:
                    'Enter PIN code',
                icon:
                    Icons.pin_drop_outlined,
                keyboardType:
                    TextInputType.number,
              ),

              // ==================================================
              // MAP BUTTON REMOVED
              // ==================================================

              const SizedBox(height: 28),

              if (_savedAddresses
                  .isNotEmpty) ...[
                AddressScreenWidgets
                    .sectionTitle(
                  'Saved Addresses',
                  'Select or manage your saved address',
                ),

                const SizedBox(height: 14),

                ...List.generate(
                  _savedAddresses.length,
                  (int index) {
                    final Map<String, dynamic>
                        address =
                        _savedAddresses[index];

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child:
                          AddressScreenWidgets
                              .savedAddressCard(
                        index:
                            index,
                        address:
                            address,
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

                const SizedBox(height: 12),
              ],

              // ==================================================
              // SAVE ADDRESS
              // ==================================================

              SizedBox(
                width: double.infinity,
                child:
                    ElevatedButton(
                  onPressed:
                      _saving
                          ? null
                          : _saveAddress,
                  child:
                      _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Text(
                              'Save Address',
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
