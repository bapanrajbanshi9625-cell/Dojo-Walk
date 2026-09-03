// File: lib/screens/address_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/app_colors.dart';
import '../services/address_location_service.dart';
import '../widgets/address_screen_widgets.dart';
import 'address_location_picker_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({
    super.key,
    this.onAddressSaved,
  });

  final VoidCallback? onAddressSaved;

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _addressLine1Controller =
      TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // LOCATION
  // ============================================================

  final AddressLocationService _locationService =
      AddressLocationService();

  double? _selectedLatitude;
  double? _selectedLongitude;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;

  DocumentReference<Map<String, dynamic>>? _ownerRef;

  final List<Map<String, dynamic>> _savedAddresses =
      <Map<String, dynamic>>[];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadAddress();
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
  // FIND OWNER
  //
  // ONLY owners collection is used.
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>?>
      _findOwner() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('owners')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.reference;
    }

    // ------------------------------------------------------------
    // Optional fallback:
    // Some projects use Firebase UID as the owners document ID.
    // Still ONLY owners collection.
    // ------------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> uidRef =
        _firestore.collection('owners').doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> uidDoc =
        await uidRef.get();

    if (uidDoc.exists) {
      return uidRef;
    }

    return null;
  }

  // ============================================================
  // LOAD ADDRESS
  //
  // Reads:
  // owners/{ownerId}/address
  //
  // address is a MAP.
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

      final DocumentReference<Map<String, dynamic>>?
          ownerRef = await _findOwner();

      if (ownerRef == null) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      _ownerRef = ownerRef;

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ownerRef.get();

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      // ----------------------------------------------------------
      // CANONICAL ADDRESS MAP
      // ----------------------------------------------------------

      final dynamic rawAddress = data['address'];

      final Map<String, dynamic> address =
          rawAddress is Map
              ? Map<String, dynamic>.from(rawAddress)
              : <String, dynamic>{};

      // ----------------------------------------------------------
      // ADDRESS FIELDS
      // ----------------------------------------------------------

      _flatController.text =
          _readString(address, 'flatNumber');

      _addressLine1Controller.text =
          _readString(address, 'addressLine1');

      _addressLine2Controller.text =
          _readString(address, 'addressLine2');

      _areaController.text =
          _readString(address, 'area');

      _cityController.text =
          _readString(address, 'city');

      _stateController.text =
          _readString(address, 'state');

      _pinCodeController.text =
          _readString(address, 'pincode');

      _selectedLatitude =
          _readDouble(address, 'latitude');

      _selectedLongitude =
          _readDouble(address, 'longitude');

      // ----------------------------------------------------------
      // LOAD SAVED ADDRESSES
      // ----------------------------------------------------------

      final dynamic savedRaw = data['savedAddresses'];

      _savedAddresses.clear();

      if (savedRaw is List) {
        for (final dynamic item in savedRaw) {
          if (item is Map) {
            _savedAddresses.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      // ----------------------------------------------------------
      // COMPATIBILITY:
      // If canonical address exists but savedAddresses doesn't,
      // create a UI-only saved address from the canonical Map.
      // ----------------------------------------------------------

      if (_savedAddresses.isEmpty && _hasAddress(address)) {
        _savedAddresses.add(
          <String, dynamic>{
            'id': 'address_1',
            'title': 'Home',
            'address': _buildFullAddress(address),
            ...address,
          },
        );
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Address load error: $e');

      if (mounted) {
        setState(() {
          _loading = false;
        });

        _showMessage(
          'Unable to load address.',
          isError: true,
        );
      }
    }
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final Position? position =
          await _locationService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      if (position == null) {
        _showMessage(
          'Unable to get your current location.',
          isError: true,
        );
        return;
      }

      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;

      // ----------------------------------------------------------
      // Open address picker with current location.
      // ----------------------------------------------------------

      final Map<String, dynamic>? result =
          await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => AddressLocationPickerScreen(
            initialLocation: LatLng(
              position.latitude,
              position.longitude,
            ),
          ),
        ),
      );

      if (result == null || !mounted) {
        return;
      }

      // ----------------------------------------------------------
      // Coordinates
      // ----------------------------------------------------------

      final dynamic latitude = result['latitude'];
      final dynamic longitude = result['longitude'];

      if (latitude is num) {
        _selectedLatitude = latitude.toDouble();
      }

      if (longitude is num) {
        _selectedLongitude = longitude.toDouble();
      }

      // ----------------------------------------------------------
      // Structured address result
      // ----------------------------------------------------------

      final dynamic rawAddress = result['address'];

      if (rawAddress is String &&
          rawAddress.trim().isNotEmpty) {
        _addressLine1Controller.text =
            rawAddress.trim();
      }

      final dynamic addressLine1 =
          result['addressLine1'];

      if (addressLine1 is String &&
          addressLine1.trim().isNotEmpty) {
        _addressLine1Controller.text =
            addressLine1.trim();
      }

      final dynamic area = result['area'];

      if (area is String && area.trim().isNotEmpty) {
        _areaController.text = area.trim();
      }

      final dynamic city = result['city'];

      if (city is String && city.trim().isNotEmpty) {
        _cityController.text = city.trim();
      }

      final dynamic state = result['state'];

      if (state is String && state.trim().isNotEmpty) {
        _stateController.text = state.trim();
      }

      final dynamic pincode = result['pincode'];

      if (pincode is String &&
          pincode.trim().isNotEmpty) {
        _pinCodeController.text = pincode.trim();
      }

      setState(() {});
    } on LocationServiceDisabledException {
      if (mounted) {
        _showMessage(
          'Please turn on location services.',
          isError: true,
        );
      }
    } on PermissionDeniedException {
      if (mounted) {
        _showMessage(
          'Location permission was denied.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Current location error: $e');

      if (mounted) {
        _showMessage(
          'Could not get your location.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE ADDRESS
  //
  // ONLY writes to:
  // owners/{ownerId}
  //
  // address = MAP
  //
  // NO root latitude
  // NO root longitude
  // NO users
  // NO ownerProfiles
  // ============================================================

  Future<void> _saveAddress() async {
    if (_saving) {
      return;
    }

    // ----------------------------------------------------------
    // Trim values
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // Validation
    // ----------------------------------------------------------

    if (line1.isEmpty) {
      _showMessage(
        'Please enter your address.',
        isError: true,
      );
      return;
    }

    if (area.isEmpty) {
      _showMessage(
        'Please enter your area/locality.',
        isError: true,
      );
      return;
    }

    if (city.isEmpty) {
      _showMessage(
        'Please enter your city.',
        isError: true,
      );
      return;
    }

    if (state.isEmpty) {
      _showMessage(
        'Please enter your state.',
        isError: true,
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage(
        'Please enter a valid 6-digit PIN code.',
        isError: true,
      );
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // Find owner ONLY from owners collection.
      // --------------------------------------------------------

      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerRef;

      ownerRef ??= await _findOwner();

      // --------------------------------------------------------
      // If owner doesn't exist, use owners/{uid}.
      // Still ONLY owners.
      // --------------------------------------------------------

      ownerRef ??=
          _firestore.collection('owners').doc(user.uid);

      _ownerRef = ownerRef;

      // --------------------------------------------------------
      // CANONICAL ADDRESS MAP
      //
      // EXACT structure:
      //
      // address
      // ├── flatNumber
      // ├── addressLine1
      // ├── addressLine2
      // ├── area
      // ├── city
      // ├── state
      // ├── pincode
      // ├── latitude
      // └── longitude
      // --------------------------------------------------------

      final Map<String, dynamic> address =
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

      // --------------------------------------------------------
      // SAVED ADDRESS FOR EXISTING UI
      // --------------------------------------------------------

      final String fullAddress =
          _buildFullAddress(address);

      final Map<String, dynamic> savedAddress =
          <String, dynamic>{
        'id': 'address_1',
        'title': 'Home',
        'address': fullAddress,
        ...address,
      };

      final List<Map<String, dynamic>> addresses =
          <Map<String, dynamic>>[
        savedAddress,
      ];

      // --------------------------------------------------------
      // WRITE ONLY TO OWNERS
      //
      // merge:true preserves existing:
      // ownerId
      // ownerName
      // pets
      // profileCompleted
      // role
      // etc.
      // --------------------------------------------------------

      await ownerRef.set(
        <String, dynamic>{
          'authUid': user.uid,
          'address': address,
          'savedAddresses': addresses,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // --------------------------------------------------------
      // Local state
      // --------------------------------------------------------

      _savedAddresses
        ..clear()
        ..add(savedAddress);

      if (!mounted) {
        return;
      }

      setState(() {});

      _showMessage(
        'Address saved successfully.',
      );

      // --------------------------------------------------------
      // Callback
      // --------------------------------------------------------

      widget.onAddressSaved?.call();

      // --------------------------------------------------------
      // Return to previous screen.
      // --------------------------------------------------------

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Save address error: $e');

      if (mounted) {
        _showMessage(
          'Failed to save address. Please try again.',
          isError: true,
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
  // DELETE ADDRESS
  // ============================================================

  Future<void> _deleteAddress(int index) async {
    if (_ownerRef == null) {
      return;
    }

    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete address?'),
          content: const Text(
            'Are you sure you want to delete this saved address?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final List<Map<String, dynamic>> addresses =
          _savedAddresses
              .where((Map<String, dynamic> item) =>
                  item != _savedAddresses[index])
              .map(
                (Map<String, dynamic> item) =>
                    Map<String, dynamic>.from(item),
              )
              .toList();

      final Map<String, dynamic> update =
          <String, dynamic>{
        'savedAddresses': addresses,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ----------------------------------------------------------
      // If no saved address remains, remove canonical address too.
      // This keeps Insta Walk/address checks correct.
      // ----------------------------------------------------------

      if (addresses.isEmpty) {
        update['address'] = FieldValue.delete();
      }

      await _ownerRef!.set(
        update,
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);

        if (addresses.isEmpty) {
          _flatController.clear();
          _addressLine1Controller.clear();
          _addressLine2Controller.clear();
          _areaController.clear();
          _cityController.clear();
          _stateController.clear();
          _pinCodeController.clear();

          _selectedLatitude = null;
          _selectedLongitude = null;
        }
      });

      _showMessage(
        'Address deleted.',
      );
    } catch (e) {
      debugPrint('Delete address error: $e');

      if (mounted) {
        _showMessage(
          'Could not delete address.',
          isError: true,
        );
      }
    }
  }

  // ============================================================
  // EDIT ADDRESS
  // ============================================================

  void _editAddress(
    Map<String, dynamic> address,
  ) {
    _flatController.text =
        _readString(address, 'flatNumber');

    _addressLine1Controller.text =
        _readString(address, 'addressLine1');

    _addressLine2Controller.text =
        _readString(address, 'addressLine2');

    _areaController.text =
        _readString(address, 'area');

    _cityController.text =
        _readString(address, 'city');

    _stateController.text =
        _readString(address, 'state');

    _pinCodeController.text =
        _readString(address, 'pincode');

    _selectedLatitude =
        _readDouble(address, 'latitude');

    _selectedLongitude =
        _readDouble(address, 'longitude');

    setState(() {});
  }

  // ============================================================
  // SELECT SAVED ADDRESS
  // ============================================================

  void _selectAddress(
    Map<String, dynamic> address,
  ) {
    _editAddress(address);
  }

  // ============================================================
  // BUILD FULL ADDRESS
  // ============================================================

  String _buildFullAddress(
    Map<String, dynamic> address,
  ) {
    final List<String> parts = <String>[];

    final String flat =
        _readString(address, 'flatNumber');

    final String line1 =
        _readString(address, 'addressLine1');

    final String line2 =
        _readString(address, 'addressLine2');

    final String area =
        _readString(address, 'area');

    final String city =
        _readString(address, 'city');

    final String state =
        _readString(address, 'state');

    final String pin =
        _readString(address, 'pincode');

    if (flat.isNotEmpty) {
      parts.add(flat);
    }

    if (line1.isNotEmpty) {
      parts.add(line1);
    }

    if (line2.isNotEmpty) {
      parts.add(line2);
    }

    if (area.isNotEmpty) {
      parts.add(area);
    }

    if (city.isNotEmpty) {
      parts.add(city);
    }

    if (state.isNotEmpty) {
      parts.add(state);
    }

    if (pin.isNotEmpty) {
      parts.add(pin);
    }

    return parts.join(', ');
  }

  // ============================================================
  // HAS ADDRESS
  // ============================================================

  bool _hasAddress(
    Map<String, dynamic> address,
  ) {
    return _readString(
              address,
              'addressLine1',
            ).isNotEmpty ||
        _readString(
              address,
              'area',
            ).isNotEmpty ||
        _readString(
              address,
              'city',
            ).isNotEmpty ||
        _readString(
              address,
              'pincode',
            ).isNotEmpty;
  }

  // ============================================================
  // READ STRING
  // ============================================================

  String _readString(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value == null) {
      return '';
    }

    return value.toString();
  }

  // ============================================================
  // READ DOUBLE
  // ============================================================

  double? _readDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : AppColors.primary,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Address'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: <Widget>[
              // ==================================================
              // CURRENT LOCATION
              // ==================================================

              AddressCurrentLocationCard(
                loading: _gettingLocation,
                onTap: _useCurrentLocation,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SAVED ADDRESSES
              // ==================================================

              if (_savedAddresses.isNotEmpty) ...<Widget>[
                const AddressSectionTitle(
                  title: 'Saved Addresses',
                ),
                const SizedBox(height: 10),

                ...List<Widget>.generate(
                  _savedAddresses.length,
                  (int index) {
                    final Map<String, dynamic> address =
                        _savedAddresses[index];

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: AddressSavedCard(
                        address: address,
                        onTap: () {
                          _selectAddress(address);
                        },
                        onEdit: () {
                          _editAddress(address);
                        },
                        onDelete: () {
                          _deleteAddress(index);
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],

              // ==================================================
              // FORM
              // ==================================================

              const AddressSectionTitle(
                title: 'Address Details',
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _flatController,
                label: 'Flat / House No.',
                hint: 'Enter flat or house number',
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _addressLine1Controller,
                label: 'Address Line 1',
                hint: 'House, street, building',
                required: true,
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _addressLine2Controller,
                label: 'Address Line 2 / Landmark',
                hint: 'Landmark or additional details',
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _areaController,
                label: 'Area / Locality',
                hint: 'Enter area or locality',
                required: true,
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                required: true,
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _stateController,
                label: 'State',
                hint: 'Enter state',
                required: true,
              ),

              const SizedBox(height: 12),

              AddressTextField(
                controller: _pinCodeController,
                label: 'PIN Code',
                hint: '6-digit PIN code',
                required: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _saving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
