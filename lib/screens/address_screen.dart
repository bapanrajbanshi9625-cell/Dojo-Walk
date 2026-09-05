import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
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
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final query = await _firestore
          .collection('owners')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.reference;
      }

      return _firestore.collection('owners').doc(user.uid);
    } catch (_) {
      return _firestore.collection('owners').doc(user.uid);
    }
  }

  Future<void> _loadAddress() async {
    try {
      final ref = await _findOwnerProfile();

      if (!mounted) return;

      if (ref == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      _ownerProfileRef = ref;

      final snapshot = await ref.get();

      if (!snapshot.exists) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final data = snapshot.data();

      if (data == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final address = data['address'];

      if (address is Map<String, dynamic>) {
        _flatController.text = address['flatNumber']?.toString() ?? '';
        _addressLine1Controller.text =
            address['addressLine1']?.toString() ?? '';
        _addressLine2Controller.text =
            address['addressLine2']?.toString() ?? '';
        _areaController.text = address['area']?.toString() ?? '';
        _cityController.text = address['city']?.toString() ?? '';
        _stateController.text = address['state']?.toString() ?? '';
        _pinCodeController.text = address['pincode']?.toString() ?? '';

        final latitude = address['latitude'];
        final longitude = address['longitude'];

        if (latitude is num && longitude is num) {
          _selectedLatitude = latitude.toDouble();
          _selectedLongitude = longitude.toDouble();
        }
      }

      final saved = data['savedAddresses'];

      if (saved is List) {
        _savedAddresses = saved
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
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

  Future<void> _populateAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return;

      final place = placemarks.first;

      final street = [
        place.name,
        place.street,
      ].where((value) {
        return value != null && value.trim().isNotEmpty;
      }).map((value) => value!.trim()).toSet().join(', ');

      final area = [
        place.subLocality,
        place.subAdministrativeArea,
      ].where((value) {
        return value != null && value.trim().isNotEmpty;
      }).map((value) => value!.trim()).toSet().join(', ');

      final city = place.locality?.trim() ?? '';
      final state = place.administrativeArea?.trim() ?? '';
      final postalCode = place.postalCode?.trim() ?? '';

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
      // Reverse geocoding failure should not remove the exact coordinates.
    }
  }

  String _buildFullAddress() {
    final parts = <String>[
      _flatController.text.trim(),
      _addressLine1Controller.text.trim(),
      _addressLine2Controller.text.trim(),
      _areaController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _pinCodeController.text.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(', ');
  }

  Future<void> _openLocationPicker() async {
    final LatLng? initialLocation =
        _selectedLatitude != null && _selectedLongitude != null
            ? LatLng(
                _selectedLatitude!,
                _selectedLongitude!,
              )
            : null;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressLocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final latitude = result['latitude'];
    final longitude = result['longitude'];

    if (latitude is! num || longitude is! num) {
      return;
    }

    // EXACT location selected by the center pin.
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
          content: Text('Please choose your pickup location on the map.'),
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

    setState(() {
      _saving = true;
    });

    try {
      final fullAddress = _buildFullAddress();

      final addressData = <String, dynamic>{
        'address': fullAddress,
        'flatNumber': _flatController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'addressLine2': _addressLine2Controller.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pinCodeController.text.trim(),
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
      };

      final savedAddress = <String, dynamic>{
        ...addressData,
      };

      await _ownerProfileRef!.set(
        {
          'authUid': _auth.currentUser?.uid,
          'address': addressData,
          'savedAddresses': [savedAddress],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses = [savedAddress];
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
    setState(() {
      _flatController.text = address['flatNumber']?.toString() ?? '';
      _addressLine1Controller.text =
          address['addressLine1']?.toString() ?? '';
      _addressLine2Controller.text =
          address['addressLine2']?.toString() ?? '';
      _areaController.text = address['area']?.toString() ?? '';
      _cityController.text = address['city']?.toString() ?? '';
      _stateController.text = address['state']?.toString() ?? '';
      _pinCodeController.text = address['pincode']?.toString() ?? '';

      final latitude = address['latitude'];
      final longitude = address['longitude'];

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
        {
          'address': FieldValue.delete(),
          'savedAddresses': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _savedAddresses = [];
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasSelectedLocation =
        _selectedLatitude != null && _selectedLongitude != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Address',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AddressScreenWidgets.bookingHeader(),

              const SizedBox(height: 16),

              // OLD "Pickup Location / Current Location" CARD REMOVED.
              // This is now the only pickup-location selector.
              AddressScreenWidgets.choosePickupLocationCard(
                selected: hasSelectedLocation,
                disabled: _saving,
                onTap: _openLocationPicker,
              ),

              const SizedBox(height: 24),

              AddressScreenWidgets.sectionTitle(
                'Your Address',
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _flatController,
                label: 'Flat / House Number',
                hint: 'Enter flat or house number',
                icon: Icons.home_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _addressLine1Controller,
                label: 'Address Line 1',
                hint: 'House, building, street',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _addressLine2Controller,
                label: 'Address Line 2',
                hint: 'Landmark, floor, etc. (optional)',
                icon: Icons.signpost_outlined,
                required: false,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _areaController,
                label: 'Area',
                hint: 'Enter your area',
                icon: Icons.map_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _cityController,
                label: 'City',
                hint: 'Enter city',
                icon: Icons.location_city_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _stateController,
                label: 'State',
                hint: 'Enter state',
                icon: Icons.public_outlined,
              ),

              const SizedBox(height: 12),

              AddressScreenWidgets.field(
                controller: _pinCodeController,
                label: 'PIN Code',
                hint: 'Enter 6-digit PIN code',
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),

              if (_savedAddresses.isNotEmpty) ...[
                const SizedBox(height: 28),

                AddressScreenWidgets.sectionTitle(
                  'Saved Address',
                ),

                const SizedBox(height: 12),

                ..._savedAddresses.map(
                  (address) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AddressScreenWidgets.savedAddressCard(
                      address: address,
                      onSelect: () => _selectAddress(address),
                      onEdit: _editAddress,
                      onDelete: _deleteAddress,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.5),
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
