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
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

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

  // =========================================================
  // FIREBASE
  // =========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // LOCATION
  // =========================================================

  final AddressLocationService _locationService =
      AddressLocationService();

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;

  // =========================================================
  // SELECTED GPS
  // =========================================================

  double? _selectedLatitude;
  double? _selectedLongitude;

  // =========================================================
  // OWNER PROFILE
  // =========================================================

  DocumentReference<Map<String, dynamic>>?
      _ownerProfileRef;

  // =========================================================
  // SAVED ADDRESSES
  // =========================================================

  final List<Map<String, dynamic>> _savedAddresses =
      <Map<String, dynamic>>[];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // =========================================================
  // FIND OWNER PROFILE
  //
  // IMPORTANT:
  // 1. Search authUid
  // 2. Search ownerAuthUid
  // 3. Check document ID == Firebase UID
  // =========================================================

  Future<DocumentReference<Map<String, dynamic>>?>
      _findOwnerProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        '❌ FIND OWNER PROFILE: Firebase user is null.',
      );
      return null;
    }

    final String uid = user.uid;

    debugPrint(
      '🔎 Finding owner profile for UID: $uid',
    );

    try {
      // =======================================================
      // METHOD 1
      // authUid == Firebase UID
      // =======================================================

      final QuerySnapshot<Map<String, dynamic>>
          authUidQuery = await _firestore
              .collection('ownerProfiles')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (authUidQuery.docs.isNotEmpty) {
        debugPrint(
          '✅ Owner profile found using authUid.',
        );

        return authUidQuery.docs.first.reference;
      }

      // =======================================================
      // METHOD 2
      // ownerAuthUid == Firebase UID
      // =======================================================

      final QuerySnapshot<Map<String, dynamic>>
          ownerAuthUidQuery = await _firestore
              .collection('ownerProfiles')
              .where(
                'ownerAuthUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (ownerAuthUidQuery.docs.isNotEmpty) {
        debugPrint(
          '✅ Owner profile found using ownerAuthUid.',
        );

        return ownerAuthUidQuery.docs.first.reference;
      }

      // =======================================================
      // METHOD 3
      // DOCUMENT ID == FIREBASE UID
      // =======================================================

      final DocumentReference<Map<String, dynamic>>
          uidDocument =
          _firestore.collection('ownerProfiles').doc(uid);

      final DocumentSnapshot<Map<String, dynamic>>
          uidSnapshot =
          await uidDocument.get();

      if (uidSnapshot.exists) {
        debugPrint(
          '✅ Owner profile found using document ID.',
        );

        return uidDocument;
      }

      // =======================================================
      // NOTHING FOUND
      // =======================================================

      debugPrint(
        '❌ Owner profile not found for UID: $uid',
      );

      return null;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ FIND OWNER PROFILE ERROR: '
        '${e.code} - ${e.message}',
      );

      rethrow;
    } catch (e) {
      debugPrint(
        '❌ FIND OWNER PROFILE UNKNOWN ERROR: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // LOAD ADDRESS
  // =========================================================

  Future<void> _loadAddress() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      _showMessage(
        'Please login first.',
      );

      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>>?
          ownerRef =
          await _findOwnerProfile();

      if (ownerRef == null) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }

        _showMessage(
          'Owner profile not found.',
        );

        return;
      }

      _ownerProfileRef = ownerRef;

      debugPrint(
        '✅ Owner profile path: ${ownerRef.path}',
      );

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await ownerRef.get();

      if (!snapshot.exists) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }

        _showMessage(
          'Owner profile not found.',
        );

        return;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      // =======================================================
      // STRUCTURED ADDRESS
      // =======================================================

      _flatController.text =
          _readString(data, 'flatNumber');

      _addressLine1Controller.text =
          _readString(data, 'addressLine1');

      _addressLine2Controller.text =
          _readString(data, 'addressLine2');

      _areaController.text =
          _readString(data, 'area');

      _cityController.text =
          _readString(data, 'city');

      _stateController.text =
          _readString(data, 'state');

      final String pincode =
          _readString(data, 'pincode');

      _pinCodeController.text =
          pincode.isNotEmpty
              ? pincode
              : _readString(data, 'Pincode');

      // =======================================================
      // GPS
      // =======================================================

      _selectedLatitude =
          _readDouble(data, 'latitude');

      _selectedLongitude =
          _readDouble(data, 'longitude');

      // =======================================================
      // OLD ADDRESS FALLBACK
      // =======================================================

      String oldAddress =
          _readString(data, 'address');

      if (oldAddress.isEmpty) {
        oldAddress =
            _readString(data, 'Adress');
      }

      if (_addressLine1Controller.text.trim().isEmpty &&
          oldAddress.isNotEmpty) {
        _addressLine1Controller.text =
            oldAddress;
      }

      // =======================================================
      // SAVED ADDRESSES
      // =======================================================

      _savedAddresses.clear();

      final dynamic firebaseAddresses =
          data['savedAddresses'];

      if (firebaseAddresses is List) {
        for (final dynamic item
            in firebaseAddresses) {
          if (item is Map) {
            _savedAddresses.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      // =======================================================
      // OLD ADDRESS -> SAVED ADDRESS
      // =======================================================

      if (_savedAddresses.isEmpty &&
          oldAddress.isNotEmpty) {
        _savedAddresses.add(
          <String, dynamic>{
            'id': 'address_1',
            'title': 'Home',
            'address': oldAddress,
            'flatNumber':
                _readString(data, 'flatNumber'),
            'addressLine1':
                _readString(data, 'addressLine1'),
            'addressLine2':
                _readString(data, 'addressLine2'),
            'area':
                _readString(data, 'area'),
            'city':
                _readString(data, 'city'),
            'state':
                _readString(data, 'state'),
            'pincode':
                pincode.isNotEmpty
                    ? pincode
                    : _readString(
                        data,
                        'Pincode',
                      ),
            'latitude':
                _selectedLatitude,
            'longitude':
                _selectedLongitude,
          },
        );
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ ADDRESS LOAD FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        e.code == 'permission-denied'
            ? 'You do not have permission to read addresses.'
            : 'Unable to load addresses.',
      );
    } catch (e) {
      debugPrint(
        '❌ ADDRESS LOAD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load addresses.',
      );
    }
  }

  // =========================================================
  // SAFE STRING
  // =========================================================

  String _readString(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // =========================================================
  // SAFE DOUBLE
  // =========================================================

  double? _readDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  // =========================================================
  // CURRENT LOCATION / MAP PICKER
  // =========================================================

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation || _saving) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final Map<String, dynamic>? result =
          await Navigator.of(context).push<
              Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) =>
              AddressLocationPickerScreen(
            initialLocation:
                _selectedLatitude != null &&
                        _selectedLongitude != null
                    ? LatLng(
                        _selectedLatitude!,
                        _selectedLongitude!,
                      )
                    : null,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        setState(() {
          _gettingLocation = false;
        });

        return;
      }

      final double? latitude =
          _readResultDouble(
        result,
        'latitude',
      );

      final double? longitude =
          _readResultDouble(
        result,
        'longitude',
      );

      if (latitude == null ||
          longitude == null) {
        setState(() {
          _gettingLocation = false;
        });

        _showMessage(
          'Location could not be selected.',
        );

        return;
      }

      _selectedLatitude = latitude;
      _selectedLongitude = longitude;

      // =======================================================
      // ADDRESS FROM MAP
      // =======================================================

      final String fullAddress =
          result['address']
                  ?.toString()
                  .trim() ??
              '';

      if (fullAddress.isNotEmpty) {
        _addressLine1Controller.text =
            fullAddress;
      }

      // =======================================================
      // STRUCTURED RESULT SUPPORT
      // =======================================================

      final String resultFlat =
          result['flatNumber']
                  ?.toString()
                  .trim() ??
              '';

      final String resultLine1 =
          result['addressLine1']
                  ?.toString()
                  .trim() ??
              '';

      final String resultLine2 =
          result['addressLine2']
                  ?.toString()
                  .trim() ??
              '';

      final String resultArea =
          result['area']
                  ?.toString()
                  .trim() ??
              '';

      final String resultCity =
          result['city']
                  ?.toString()
                  .trim() ??
              '';

      final String resultState =
          result['state']
                  ?.toString()
                  .trim() ??
              '';

      final String resultPincode =
          result['pincode']
                  ?.toString()
                  .trim() ??
              '';

      if (resultFlat.isNotEmpty) {
        _flatController.text = resultFlat;
      }

      if (resultLine1.isNotEmpty) {
        _addressLine1Controller.text =
            resultLine1;
      }

      if (resultLine2.isNotEmpty) {
        _addressLine2Controller.text =
            resultLine2;
      }

      if (resultArea.isNotEmpty) {
        _areaController.text = resultArea;
      }

      if (resultCity.isNotEmpty) {
        _cityController.text = resultCity;
      }

      if (resultState.isNotEmpty) {
        _stateController.text = resultState;
      }

      if (resultPincode.isNotEmpty) {
        _pinCodeController.text =
            resultPincode;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showMessage(
        'Location selected. Please verify the address and save.',
      );
    } on LocationServiceDisabledException {
      if (!mounted) {
        return;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showLocationServiceDialog();
    } on LocationPermissionDeniedException {
      if (!mounted) {
        return;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showMessage(
        'Location permission is required.',
      );
    } on LocationPermissionDeniedForeverException {
      if (!mounted) {
        return;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showLocationPermissionDialog();
    } on AddressNotFoundException {
      if (!mounted) {
        return;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showMessage(
        'Location detected, but address details could not be found.',
      );
    } catch (e) {
      debugPrint(
        '❌ LOCATION PICKER ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _gettingLocation = false;
      });

      _showMessage(
        'Unable to select location.',
      );
    }
  }

  // =========================================================
  // READ RESULT DOUBLE
  // =========================================================

  double? _readResultDouble(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  // =========================================================
  // LOCATION SERVICE DIALOG
  // =========================================================

  void _showLocationServiceDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Location is Off',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Please turn on your device location to automatically detect your address.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _locationService
                    .openLocationSettings();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    AppColors.white,
              ),
              child: const Text(
                'Turn On',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // PERMISSION DIALOG
  // =========================================================

  void _showLocationPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Location Permission Needed',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Location permission was permanently denied. Please enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                _locationService
                    .openAppSettings();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    AppColors.white,
              ),
              child: const Text(
                'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD FULL ADDRESS
  // =========================================================

  String _buildFullAddress({
    required String flat,
    required String line1,
    required String line2,
    required String area,
    required String city,
    required String state,
    required String pin,
  }) {
    final List<String> parts =
        <String>[];

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

  // =========================================================
  // SAVE ADDRESS
  // =========================================================

  Future<void> _saveAddress() async {
    if (_saving) {
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

    // =======================================================
    // VALIDATION
    // =======================================================

    if (line1.isEmpty) {
      _showMessage(
        'Please enter Address Line 1.',
      );
      return;
    }

    if (area.isEmpty) {
      _showMessage(
        'Please enter your area or locality.',
      );
      return;
    }

    if (city.isEmpty) {
      _showMessage(
        'Please enter your city.',
      );
      return;
    }

    if (state.isEmpty) {
      _showMessage(
        'Please enter your state.',
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage(
        'Please enter a valid 6-digit PIN code.',
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // =======================================================
      // FIND OWNER PROFILE
      // =======================================================

      DocumentReference<Map<String, dynamic>>?
          ownerRef =
          _ownerProfileRef;

      ownerRef ??=
          await _findOwnerProfile();

      // =======================================================
      // IMPORTANT:
      // If no existing owner profile is found,
      // use ownerProfiles/{Firebase UID}.
      //
      // This fixes "Owner profile not found" when
      // profile document uses Firebase UID as document ID.
      // =======================================================

      ownerRef ??=
          _firestore
              .collection('ownerProfiles')
              .doc(user.uid);

      _ownerProfileRef = ownerRef;

      debugPrint(
        '💾 Saving owner profile: ${ownerRef.path}',
      );

      // =======================================================
      // FULL ADDRESS
      // =======================================================

      final String fullAddress =
          _buildFullAddress(
        flat: flat,
        line1: line1,
        line2: line2,
        area: area,
        city: city,
        state: state,
        pin: pin,
      );

      // =======================================================
      // NEW ADDRESS
      // =======================================================

      final Map<String, dynamic>
          newAddress =
          <String, dynamic>{
        'id': _savedAddresses.isEmpty
            ? 'address_1'
            : (_savedAddresses.first['id']
                    ?.toString() ??
                'address_1'),
        'title': _savedAddresses.isEmpty
            ? 'Home'
            : (_savedAddresses.first['title']
                    ?.toString() ??
                'Home'),
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

      // =======================================================
      // SAVED ADDRESSES
      // =======================================================

      final List<Map<String, dynamic>>
          addresses =
          _savedAddresses
              .map(
                (Map<String, dynamic> item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      if (addresses.isEmpty) {
        addresses.add(
          newAddress,
        );
      } else {
        addresses[0] =
            newAddress;
      }

      // =======================================================
      // OWNER PROFILE
      // =======================================================

      await ownerRef.set(
        <String, dynamic>{
          // Firebase identity
          'authUid': user.uid,
          'ownerAuthUid': user.uid,

          // Address
          'address': fullAddress,
          'flatNumber': flat,
          'addressLine1': line1,
          'addressLine2': line2,
          'area': area,
          'city': city,
          'state': state,
          'pincode': pin,

          // GPS
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,

          // Saved addresses
          'savedAddresses': addresses,

          // Timestamp
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        '✅ Owner profile address saved.',
      );

      // =======================================================
      // USERS SYNC
      // =======================================================

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'uid': user.uid,
          'authUid': user.uid,

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

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        '✅ Users address synced.',
      );

      // =======================================================
      // LOCAL UPDATE
      // =======================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);

        _saving = false;
      });

      _showMessage(
        'Address and location saved successfully.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ ADDRESS SAVE FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        e.code == 'permission-denied'
            ? 'You do not have permission to save this address.'
            : 'Unable to save address.',
      );
    } catch (e) {
      debugPrint(
        '❌ ADDRESS SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to save address.',
      );
    }
  }

  // =========================================================
  // SELECT ADDRESS
  // =========================================================

  void _selectAddress(
    Map<String, dynamic> address,
  ) {
    Navigator.pop(
      context,
      <String, dynamic>{
        'selected': true,
        ...address,
      },
    );
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

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
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Address?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This address will be removed from your saved addresses.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.bold,
                ),
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
      final List<Map<String, dynamic>>
          addresses =
          _savedAddresses
              .map(
                (Map<String, dynamic> item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      addresses.removeAt(index);

      if (_ownerProfileRef != null) {
        await _ownerProfileRef!.set(
          <String, dynamic>{
            'savedAddresses':
                addresses,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);
      });

      _showMessage(
        'Address deleted.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ DELETE ADDRESS FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (mounted) {
        _showMessage(
          e.code == 'permission-denied'
              ? 'You do not have permission to delete this address.'
              : 'Unable to delete address.',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ DELETE ADDRESS ERROR: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to delete address.',
        );
      }
    }
  }

  // =========================================================
  // EDIT ADDRESS
  // =========================================================

  void _editAddress(
    Map<String, dynamic> address,
  ) {
    _flatController.text =
        address['flatNumber']?.toString() ??
            '';

    _addressLine1Controller.text =
        address['addressLine1']?.toString() ??
            '';

    _addressLine2Controller.text =
        address['addressLine2']?.toString() ??
            '';

    _areaController.text =
        address['area']?.toString() ??
            '';

    _cityController.text =
        address['city']?.toString() ??
            '';

    _stateController.text =
        address['state']?.toString() ??
            '';

    _pinCodeController.text =
        address['pincode']?.toString() ??
            address['Pincode']?.toString() ??
            '';

    _selectedLatitude =
        _readResultDouble(
      address,
      'latitude',
    );

    _selectedLongitude =
        _readResultDouble(
      address,
      'longitude',
    );

    _showMessage(
      'Address loaded. Update the details and save.',
    );

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // MESSAGE
  // =========================================================

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
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          backgroundColor:
              AppColors.navy,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      // =======================================================
      // APP BAR
      // =======================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Choose Walking Address',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // =======================================================
      // BODY
      // =======================================================

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // HEADER
                  // =================================================

                  AddressScreenWidgets
                      .bookingHeader(),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // CURRENT LOCATION
                  // =================================================

                  AddressScreenWidgets
                      .currentLocationCard(
                    gettingLocation:
                        _gettingLocation,
                    disabled:
                        _gettingLocation ||
                            _saving,
                    onTap:
                        _useCurrentLocation,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =================================================
                  // SAVED ADDRESSES
                  // =================================================

                  if (_savedAddresses
                      .isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved Addresses',
                            style: TextStyle(
                              color:
                                  AppColors.navy,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: .10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${_savedAddresses.length}',
                            style:
                                const TextStyle(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Tap an address to use it for your booking.',
                      style: TextStyle(
                        color:
                            AppColors.slate
                                .withValues(
                          alpha: .75,
                        ),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    ...List.generate(
                      _savedAddresses.length,
                      (int index) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child:
                              AddressScreenWidgets
                                  .savedAddressCard(
                            index: index,
                            address:
                                _savedAddresses[
                                    index],
                            onSelect: () =>
                                _selectAddress(
                              _savedAddresses[
                                  index],
                            ),
                            onEdit: () =>
                                _editAddress(
                              _savedAddresses[
                                  index],
                            ),
                            onDelete: () =>
                                _deleteAddress(
                              index,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),
                  ],

                  // =================================================
                  // ADD NEW ADDRESS
                  // =================================================

                  AddressScreenWidgets
                      .sectionTitle(
                    'Add New Address',
                    'Enter your walking location.',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // FLAT
                  // =================================================

                  AddressScreenWidgets.field(
                    controller:
                        _flatController,
                    label:
                        'Flat / House No.',
                    hint:
                        'Flat 204 / House No. 12',
                    icon:
                        Icons.home_outlined,
                    requiredField:
                        false,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =================================================
                  // ADDRESS LINE 1
                  // =================================================

                  AddressScreenWidgets.field(
                    controller:
                        _addressLine1Controller,
                    label:
                        'Address Line 1',
                    hint:
                        'Street / Road / Building',
                    icon:
                        Icons
                            .location_on_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =================================================
                  // ADDRESS LINE 2
                  // =================================================

                  AddressScreenWidgets.field(
                    controller:
                        _addressLine2Controller,
                    label:
                        'Address Line 2 / Landmark',
                    hint:
                        'Nearby place / landmark',
                    icon:
                        Icons
                            .signpost_outlined,
                    requiredField:
                        false,
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =================================================
                  // AREA
                  // =================================================

                  AddressScreenWidgets.field(
                    controller:
                        _areaController,
                    label:
                        'Area / Locality',
                    hint:
                        'Area or locality',
                    icon:
                        Icons.map_outlined,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =================================================
                  // CITY + STATE
                  // =================================================

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Expanded(
                        child:
                            AddressScreenWidgets
                                .field(
                          controller:
                              _cityController,
                          label: 'City',
                          hint: 'City',
                          icon: Icons
                              .location_city_outlined,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            AddressScreenWidgets
                                .field(
                          controller:
                              _stateController,
                          label: 'State',
                          hint: 'State',
                          icon:
                              Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  // =================================================
                  // PIN
                  // =================================================

                  AddressScreenWidgets.field(
                    controller:
                        _pinCodeController,
                    label:
                        'PIN Code',
                    hint:
                        '6-digit PIN code',
                    icon:
                        Icons
                            .pin_drop_outlined,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 6,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =================================================
                  // SAVE BUTTON
                  // =================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 54,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _saveAddress,
                      icon: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
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
                                  .check_circle_outline,
                            ),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : 'Save Address',
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            AppColors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary
                                .withValues(
                          alpha: .55,
                        ),
                        disabledForegroundColor:
                            AppColors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
