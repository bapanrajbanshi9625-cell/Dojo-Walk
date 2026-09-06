import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'address_location_picker_screen.dart';
import '../widgets/address_screen_widgets.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _flatController = TextEditingController();
  final TextEditingController _addressLine1Controller =
      TextEditingController();
  final TextEditingController _addressLine2Controller =
      TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  DocumentReference<Map<String, dynamic>>? _ownerProfileRef;

  List<Map<String, dynamic>> _savedAddresses = [];

  bool _loading = true;
  bool _saving = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  static const Color _primaryColor = Color(0xFFFF8A00);
  static const Color _backgroundColor = Color(0xFFF8F9FB);
  static const Color _textPrimaryColor = Color(0xFF202124);

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

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

  Future<DocumentReference<Map<String, dynamic>>?> _findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> query = await _firestore
          .collection('owners')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.reference;
      }
    } catch (_) {
      // Fall back to UID document below.
    }

    return _firestore.collection('owners').doc(user.uid);
  }

  Future<void> _loadAddress() async {
    try {
      final DocumentReference<Map<String, dynamic>>? ref =
          await _findOwnerProfile();

      if (!mounted) return;

      if (ref == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      _ownerProfileRef = ref;

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final Map<String, dynamic>? data = snapshot.data();

      if (data == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final dynamic rawAddress = data['address'];

      if (rawAddress is Map) {
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(rawAddress);

        _flatController.text = _stringValue(address['flatNumber']);
        _addressLine1Controller.text =
            _stringValue(address['addressLine1']);
        _addressLine2Controller.text =
            _stringValue(address['addressLine2']);
        _areaController.text = _stringValue(address['area']);
        _cityController.text = _stringValue(address['city']);
        _stateController.text = _stringValue(address['state']);
        _pinCodeController.text = _stringValue(address['pincode']);

        final dynamic latitude = address['latitude'];
        final dynamic longitude = address['longitude'];

        if (latitude is num && longitude is num) {
          _selectedLatitude = latitude.toDouble();
          _selectedLongitude = longitude.toDouble();
        }
      }

      final dynamic saved = data['savedAddresses'];

      if (saved is List) {
        _savedAddresses = saved
            .whereType<Map>()
            .map(
              (Map item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load address: $e'),
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

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  Future<void> _populateAddressFromCoordinates(
  double latitude,
  double longitude,
) async {
  try {
    final List<geocoding.Placemark> placemarks =
        await _geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
    );

      if (placemarks.isEmpty) return;

      final geocoding.Placemark place = placemarks.first;

      final List<String> streetParts = <String>[
        if (place.name != null && place.name!.trim().isNotEmpty)
          place.name!.trim(),
        if (place.street != null && place.street!.trim().isNotEmpty)
          place.street!.trim(),
      ];

      final List<String> areaParts = <String>[
        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty)
          place.subLocality!.trim(),
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.trim().isNotEmpty)
          place.subAdministrativeArea!.trim(),
      ];

      final String street = streetParts.toSet().join(', ');
      final String area = areaParts.toSet().join(', ');
      final String city = place.locality?.trim() ?? '';
      final String state = place.administrativeArea?.trim() ?? '';
      final String postalCode = place.postalCode?.trim() ?? '';

      if (!mounted) return;

      setState(() {
        if (street.isNotEmpty) {
          _addressLine1Controller.text = street;
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

        if (postalCode.isNotEmpty) {
          _pinCodeController.text = postalCode;
        }
      });
    } catch (_) {
      // Coordinates remain valid even if reverse geocoding fails.
    }
  }

  String _buildFullAddress() {
    final List<String> parts = <String>[
      _flatController.text.trim(),
      _addressLine1Controller.text.trim(),
      _addressLine2Controller.text.trim(),
      _areaController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _pinCodeController.text.trim(),
    ].where((String value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  Future<void> _openLocationPicker() async {
    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (BuildContext context) {
          return AddressLocationPickerScreen(
            initialLatitude: _selectedLatitude,
            initialLongitude: _selectedLongitude,
          );
        },
      ),
    );

    if (!mounted || result == null) return;

    final dynamic latitude = result['latitude'];
    final dynamic longitude = result['longitude'];

    if (latitude is! num || longitude is! num) {
      return;
    }

    // EXACT CENTER PIN LOCATION.
    _selectedLatitude = latitude.toDouble();
    _selectedLongitude = longitude.toDouble();

    await _populateAddressFromCoordinates(
      _selectedLatitude!,
      _selectedLongitude!,
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _saveAddress() async {
    if (_ownerProfileRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner profile not found.'),
        ),
      );
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose your pickup location on the map.',
          ),
        ),
      );
      return;
    }

    if (_addressLine1Controller.text.trim().isEmpty ||
        _areaController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _pinCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your address details.'),
        ),
      );
      return;
    }

    if (_pinCodeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit PIN code.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String fullAddress = _buildFullAddress();

      final Map<String, dynamic> addressData = <String, dynamic>{
        'address': fullAddress,
        'flatNumber': _flatController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pinCodeController.text.trim(),

        // Exact map-pin coordinates.
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
      };

      await _ownerProfileRef!.set(
        <String, dynamic>{
          'authUid': _auth.currentUser?.uid,
          'address': addressData,
          'savedAddresses': <Map<String, dynamic>>[
            Map<String, dynamic>.from(addressData),
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses = <Map<String, dynamic>>[
          Map<String, dynamic>.from(addressData),
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup address saved successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save address: $e'),
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

  void _selectAddress(Map<String, dynamic> address) {
    final dynamic latitude = address['latitude'];
    final dynamic longitude = address['longitude'];

    setState(() {
      _flatController.text = _stringValue(address['flatNumber']);
      _addressLine1Controller.text =
          _stringValue(address['addressLine1']);
      _addressLine2Controller.text =
          _stringValue(address['addressLine2']);
      _areaController.text = _stringValue(address['area']);
      _cityController.text = _stringValue(address['city']);
      _stateController.text = _stringValue(address['state']);
      _pinCodeController.text = _stringValue(address['pincode']);

      if (latitude is num && longitude is num) {
        _selectedLatitude = latitude.toDouble();
        _selectedLongitude = longitude.toDouble();
      } else {
        _selectedLatitude = null;
        _selectedLongitude = null;
      }
    });
  }

  Future<void> _editAddress() async {
    await _openLocationPicker();
  }

  Future<void> _deleteAddress() async {
    if (_ownerProfileRef == null) return;

    try {
      await _ownerProfileRef!.set(
        <String, dynamic>{
          'address': FieldValue.delete(),
          'savedAddresses': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses.clear();
        _flatController.clear();
        _addressLine1Controller.clear();
        _addressLine2Controller.clear();
        _areaController.clear();
        _cityController.clear();
        _stateController.clear();
        _pinCodeController.clear();
        _selectedLatitude = null;
        _selectedLongitude = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete address: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: _primaryColor,
          ),
        ),
      );
    }

    final bool hasSelectedLocation =
        _selectedLatitude != null && _selectedLongitude != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _backgroundColor,
        foregroundColor: _textPrimaryColor,
        title: const Text(
          'Address',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AddressScreenWidgets.bookingHeader(
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 16),

              // ONLY pickup-location selector.
              AddressScreenWidgets.choosePickupLocationCard(
                selected: hasSelectedLocation,
                disabled: _saving,
                primaryColor: _primaryColor,
                onTap: _openLocationPicker,
              ),

              const SizedBox(height: 24),

              AddressScreenWidgets.sectionTitle(
                'Your Address',
                textColor: _textPrimaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _flatController,
                label: 'Flat / House Number',
                hint: 'Enter flat or house number',
                icon: Icons.home_outlined,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _addressLine1Controller,
                label: 'Address Line 1',
                hint: 'House, building, street',
                icon: Icons.location_on_outlined,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _addressLine2Controller,
                label: 'Address Line 2',
                hint: 'Landmark, floor, etc. (optional)',
                icon: Icons.signpost_outlined,
                required: false,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _areaController,
                label: 'Area',
                hint: 'Enter your area',
                icon: Icons.map_outlined,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                icon: Icons.location_city_outlined,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _stateController,
                label: 'State',
                hint: 'Enter state',
                icon: Icons.public_outlined,
                primaryColor: _primaryColor,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _pinCodeController,
                label: 'PIN Code',
                hint: 'Enter 6-digit PIN code',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
                primaryColor: _primaryColor,
              ),

              if (_savedAddresses.isNotEmpty) ...<Widget>[
                const SizedBox(height: 28),

                AddressScreenWidgets.sectionTitle(
                  'Saved Address',
                  textColor: _textPrimaryColor,
                ),

                const SizedBox(height: 12),

                ..._savedAddresses.map(
                  (Map<String, dynamic> address) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AddressScreenWidgets.savedAddressCard(
                        address: address,
                        primaryColor: _primaryColor,
                        onSelect: () => _selectAddress(address),
                        onEdit: _editAddress,
                        onDelete: _deleteAddress,
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
