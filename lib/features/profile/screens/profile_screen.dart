import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/owner_id_service.dart';
import '../change_mobile/change_mobile_flow.dart';
import '../widgets/address_card.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/pet_details_card.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);
  static const Color background = Color(0xFFEDEFF2);
  static const Color lightOrange = Color(0xFFFFF1E8);

  String ownerId = '';
  String ownerUid = '';

  String mobileNumber = '';
  String ownerName = 'Owner';
  String ownerDob = '-';
  String ownerGender = '-';
  String memberSince = '-';

  String flatHouseNo = '';
  String streetRoad = '';
  String landmark = '';

  double? currentLatitude;
  double? currentLongitude;
  double? locationAccuracy;

  bool isActive = true;
  bool isLoading = true;
  bool isSavingPet = false;
  bool isSavingAddress = false;
  bool isConnectingLocation = false;

  List<Map<String, dynamic>> pets = [];

  bool get _hasConnectedLocation {
    return currentLatitude != null &&
        currentLongitude != null;
  }

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadOwnerProfile() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final String uid = user.uid.trim();

      final String? existingOwnerId =
          await OwnerIdService.instance.getExistingOwnerId(
        uid: uid,
      );

      if (existingOwnerId == null ||
          existingOwnerId.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          isLoading = false;
        });

        return;
      }

      final String cleanOwnerId =
          existingOwnerId.trim();

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(cleanOwnerId)
              .get();

      if (!snapshot.exists) {
        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          ownerId = cleanOwnerId;
          isLoading = false;
        });

        return;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          ownerId = cleanOwnerId;
          isLoading = false;
        });

        return;
      }

      final String fullName =
          data['fullName']
                  ?.toString()
                  .trim() ??
              '';

      final String savedOwnerName =
          data['ownerName']
                  ?.toString()
                  .trim() ??
              '';

      final String name =
          fullName.isNotEmpty
              ? fullName
              : savedOwnerName.isNotEmpty
                  ? savedOwnerName
                  : 'Owner';

      final String firestorePhone =
          data['phone']
                  ?.toString()
                  .trim() ??
              '';

      final String phone =
          firestorePhone.isNotEmpty
              ? firestorePhone
              : user.phoneNumber ?? '';

      final String dob =
          _formatDateOfBirth(
        data['dateOfBirth'],
      );

      final String savedGender =
          data['gender']
                  ?.toString()
                  .trim() ??
              '';

      final bool active =
          data['isActive'] is bool
              ? data['isActive'] as bool
              : true;

      String joinedDate = '-';

      final dynamic createdAt =
          data['createdAt'];

      if (createdAt is Timestamp) {
        final DateTime date =
            createdAt.toDate();

        joinedDate =
            '${_monthName(date.month)} '
            '${date.day}, '
            '${date.year}';
      }

      String savedFlat = '';
      String savedStreet = '';
      String savedLandmark = '';

      final dynamic addressDetails =
          data['addressDetails'];

      if (addressDetails is Map) {
        savedFlat =
            addressDetails['flatHouseNo']
                    ?.toString()
                    .trim() ??
                '';

        savedStreet =
            addressDetails['streetRoad']
                    ?.toString()
                    .trim() ??
                '';

        savedLandmark =
            addressDetails['landmark']
                    ?.toString()
                    .trim() ??
                '';
      }

      if (savedFlat.isEmpty &&
          savedStreet.isEmpty &&
          savedLandmark.isEmpty) {
        final String oldAddress =
            data['address']
                    ?.toString()
                    .trim() ??
                '';

        if (oldAddress.isNotEmpty) {
          savedStreet = oldAddress;
        }
      }

      double? savedLatitude;
      double? savedLongitude;
      double? savedAccuracy;

      final dynamic latitude =
          data['latitude'];

      final dynamic longitude =
          data['longitude'];

      final dynamic accuracy =
          data['locationAccuracy'];

      if (latitude is num &&
          longitude is num) {
        savedLatitude =
            latitude.toDouble();

        savedLongitude =
            longitude.toDouble();
      }

      if (accuracy is num) {
        savedAccuracy =
            accuracy.toDouble();
      }

      if (savedLatitude == null ||
          savedLongitude == null) {
        final dynamic location =
            data['location'];

        if (location is Map) {
          final dynamic nestedLatitude =
              location['latitude'];

          final dynamic nestedLongitude =
              location['longitude'];

          if (nestedLatitude is num &&
              nestedLongitude is num) {
            savedLatitude =
                nestedLatitude.toDouble();

            savedLongitude =
                nestedLongitude.toDouble();
          }
        }
      }

      final List<Map<String, dynamic>>
          loadedPets =
          _readPets(data['pets']);

      if (!mounted) return;

      setState(() {
        ownerUid = uid;
        ownerId = cleanOwnerId;

        mobileNumber =
            _formatIndianNumber(phone);

        ownerName = name;

        ownerDob =
            dob.isEmpty ? '-' : dob;

        ownerGender =
            savedGender.isEmpty
                ? '-'
                : savedGender;

        memberSince = joinedDate;

        isActive = active;

        flatHouseNo = savedFlat;
        streetRoad = savedStreet;
        landmark = savedLandmark;

        currentLatitude =
            savedLatitude;

        currentLongitude =
            savedLongitude;

        locationAccuracy =
            savedAccuracy;

        pets = loadedPets;

        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Owner Profile Error: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // DOB
  // ============================================================

  String _formatDateOfBirth(
    dynamic value,
  ) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      final String text =
          value.trim();

      if (text.isNotEmpty) {
        date = DateTime.tryParse(text);

        if (date == null) {
          return text;
        }
      }
    }

    if (date == null) {
      return '';
    }

    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} '
        '${date.year}';
  }

  // ============================================================
  // READ PETS
  // ============================================================

  List<Map<String, dynamic>> _readPets(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final List<Map<String, dynamic>> result = [];

    for (final dynamic item in value) {
      if (item is Map) {
        result.add(
          Map<String, dynamic>.from(item),
        );
      }
    }

    return result;
  }

  // ============================================================
  // PHONE
  // ============================================================

  String _formatIndianNumber(
    String number,
  ) {
    final String clean =
        number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length >= 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
    }

    return number.isEmpty
        ? '-'
        : number;
  }

  // ============================================================
  // MONTH
  // ============================================================

  String _monthName(int month) {
    const List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month];
  }

  // ============================================================
  // COPY OWNER ID
  // ============================================================

  Future<void> _copyOwnerId() async {
    if (ownerId.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(
        text: ownerId,
      ),
    );

    if (!mounted) return;

    _showMessage(
      'Owner ID copied.',
    );
  }

  // ============================================================
  // CHANGE MOBILE
  // ============================================================

  void _openChangeMobile() {
    if (mobileNumber.isEmpty ||
        mobileNumber == '-') {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return ChangeMobileFlow(
          currentNumber: mobileNumber,
          onChanged: (
            String newNumber,
          ) {
            if (!mounted) return;

            setState(() {
              mobileNumber = newNumber;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // GET LOCATION
  // ============================================================

  Future<Position?> _getCurrentLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on Location Services.',
        );
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is required.',
        );
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint(
        'Location Error: $e',
      );

      return null;
    }
  }

  // ============================================================
  // SAVE ADDRESS
  // ============================================================

  Future<bool> _saveAddress({
    required String flatHouseNo,
    required String streetRoad,
    required String landmark,
  }) async {
    if (ownerId.trim().isEmpty) {
      _showMessage(
        'Owner ID was not found.',
      );
      return false;
    }

    if (flatHouseNo.trim().isEmpty) {
      _showMessage(
        'Flat / House No. is required.',
      );
      return false;
    }

    if (streetRoad.trim().isEmpty) {
      _showMessage(
        'Street / Road is required.',
      );
      return false;
    }

    if (!_hasConnectedLocation) {
      _showMessage(
        'Current location is required.',
      );
      return false;
    }

    setState(() {
      isSavingAddress = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .set(
        <String, dynamic>{
          'addressDetails':
              <String, dynamic>{
            'flatHouseNo':
                flatHouseNo.trim(),
            'streetRoad':
                streetRoad.trim(),
            'landmark':
                landmark.trim(),
          },
          'address': _buildAddress(
            flatHouseNo,
            streetRoad,
            landmark,
          ),
          'latitude':
              currentLatitude,
          'longitude':
              currentLongitude,
          'location':
              <String, dynamic>{
            'latitude':
                currentLatitude,
            'longitude':
                currentLongitude,
          },
          if (locationAccuracy != null)
            'locationAccuracy':
                locationAccuracy,
          'locationUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return false;

      setState(() {
        this.flatHouseNo =
            flatHouseNo.trim();

        this.streetRoad =
            streetRoad.trim();

        this.landmark =
            landmark.trim();
      });

      _showMessage(
        'Address saved successfully.',
      );

      return true;
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Could not save address.',
        );
      }

      return false;
    } catch (e) {
      debugPrint(
        'Save Address Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not save address.',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSavingAddress = false;
        });
      }
    }
  }

  String _buildAddress(
    String flat,
    String street,
    String landmark,
  ) {
    final List<String> parts = [];

    if (flat.trim().isNotEmpty) {
      parts.add(flat.trim());
    }

    if (street.trim().isNotEmpty) {
      parts.add(street.trim());
    }

    if (landmark.trim().isNotEmpty) {
      parts.add(landmark.trim());
    }

    return parts.join(', ');
  }

  // ============================================================
  // UPDATE LOCATION
  // ============================================================

  Future<void> _updateCurrentLocation() async {
    if (ownerId.trim().isEmpty) {
      _showMessage(
        'Owner ID was not found.',
      );
      return;
    }

    if (isConnectingLocation) return;

    setState(() {
      isConnectingLocation = true;
    });

    try {
      final Position? position =
          await _getCurrentLocation();

      if (position == null) {
        return;
      }

      await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .set(
        <String, dynamic>{
          'latitude':
              position.latitude,
          'longitude':
              position.longitude,
          'location':
              <String, dynamic>{
            'latitude':
                position.latitude,
            'longitude':
                position.longitude,
          },
          'locationAccuracy':
              position.accuracy,
          'locationUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentLatitude =
            position.latitude;
        currentLongitude =
            position.longitude;
        locationAccuracy =
            position.accuracy;
      });

      _showMessage(
        'Current location connected.',
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Could not update location.',
        );
      }
    } catch (e) {
      debugPrint(
        'Update Location Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not update location.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isConnectingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // ADDRESS EDITOR
  // ============================================================

  Future<void> _openAddressEditor() async {
    final TextEditingController flatController =
        TextEditingController(
      text: flatHouseNo,
    );

    final TextEditingController streetController =
        TextEditingController(
      text: streetRoad,
    );

    final TextEditingController landmarkController =
        TextEditingController(
      text: landmark,
    );

    bool connecting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            Future<void> connectLocation() async {
              if (connecting) return;

              setSheetState(() {
                connecting = true;
              });

              try {
                final Position? position =
                    await _getCurrentLocation();

                if (position == null) {
                  return;
                }

                if (!mounted) return;

                setState(() {
                  currentLatitude =
                      position.latitude;
                  currentLongitude =
                      position.longitude;
                  locationAccuracy =
                      position.accuracy;
                });

                if (sheetContext.mounted) {
                  _showMessage(
                    'Current location connected.',
                  );
                }
              } finally {
                if (sheetContext.mounted) {
                  setSheetState(() {
                    connecting = false;
                  });
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom:
                      MediaQuery.of(context)
                              .viewInsets
                              .bottom +
                          20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color:
                                  lightOrange,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                13,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons
                                  .location_on_outlined,
                              color: orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Address',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _AddressEditorField(
                        controller:
                            flatController,
                        hint:
                            'e.g. Flat 204 / House No. 12',
                        icon:
                            Icons.home_outlined,
                      ),

                      const SizedBox(height: 14),

                      _AddressEditorField(
                        controller:
                            streetController,
                        hint:
                            'Enter street or road',
                        icon:
                            Icons.signpost_outlined,
                      ),

                      const SizedBox(height: 14),

                      _AddressEditorField(
                        controller:
                            landmarkController,
                        hint:
                            'Nearby landmark (optional)',
                        icon:
                            Icons.place_outlined,
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(13),
                        decoration:
                            BoxDecoration(
                          color:
                              _hasConnectedLocation
                                  ? Colors.green
                                      .withValues(
                                      alpha: 0.08,
                                    )
                                  : Colors.red
                                      .withValues(
                                      alpha: 0.06,
                                    ),
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                          border: Border.all(
                            color:
                                _hasConnectedLocation
                                    ? Colors.green
                                    : Colors.red
                                        .withValues(
                                        alpha: 0.35,
                                      ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasConnectedLocation
                                  ? Icons
                                      .check_circle_rounded
                                  : Icons
                                      .location_off_rounded,
                              color:
                                  _hasConnectedLocation
                                      ? Colors.green
                                      : Colors.red,
                              size: 21,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _hasConnectedLocation
                                    ? 'Current location connected'
                                    : 'Current location is required',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _hasConnectedLocation
                                          ? Colors.green
                                          : Colors.red,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed:
                              connecting
                                  ? null
                                  : connectLocation,
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                orange,
                            side:
                                const BorderSide(
                              color: orange,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                13,
                              ),
                            ),
                          ),
                          icon: connecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: orange,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .my_location_rounded,
                                ),
                          label: Text(
                            connecting
                                ? 'Connecting...'
                                : _hasConnectedLocation
                                    ? 'Update Current Location'
                                    : 'Connect Current Location',
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              isSavingAddress
                                  ? null
                                  : () async {
                                      final String
                                          flat =
                                          flatController
                                              .text
                                              .trim();

                                      final String
                                          street =
                                          streetController
                                              .text
                                              .trim();

                                      final String
                                          landmarkValue =
                                          landmarkController
                                              .text
                                              .trim();

                                      if (flat.isEmpty) {
                                        _showMessage(
                                          'Please enter Flat / House No.',
                                        );
                                        return;
                                      }

                                      if (street.isEmpty) {
                                        _showMessage(
                                          'Please enter Street / Road.',
                                        );
                                        return;
                                      }

                                      if (!_hasConnectedLocation) {
                                        _showMessage(
                                          'Please connect your current location before saving address.',
                                        );
                                        return;
                                      }

                                      final bool saved =
                                          await _saveAddress(
                                        flatHouseNo:
                                            flat,
                                        streetRoad:
                                            street,
                                        landmark:
                                            landmarkValue,
                                      );

                                      if (saved &&
                                          sheetContext
                                              .mounted) {
                                        Navigator.pop(
                                          sheetContext,
                                        );
                                      }
                                    },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                orange,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              isSavingAddress
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.3,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Address',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            15,
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
      },
    );

    flatController.dispose();
    streetController.dispose();
    landmarkController.dispose();
  }

  // ============================================================
  // PET VALUE
  // ============================================================

  String _petValue(
    Map<String, dynamic> pet,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = pet[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  // ============================================================
  // ADD PET
  // ============================================================

  Future<void> _addPet() async {
    if (pets.length >= 3) {
      _showMessage(
        'Maximum 3 pets can be added.',
      );
      return;
    }

    await _showPetEditor();
  }

  // ============================================================
  // EDIT PET
  // ============================================================

  Future<void> _editPet(int index) async {
    if (index < 0 ||
        index >= pets.length) {
      return;
    }

    await _showPetEditor(
      index: index,
      existingPet: pets[index],
    );
  }

  // ============================================================
  // DELETE PET
  // ============================================================

  Future<void> _deletePet(int index) async {
    if (pets.length <= 1) {
      _showMessage(
        'At least one pet is required.',
      );
      return;
    }

    if (index < 0 ||
        index >= pets.length) {
      return;
    }

    final String petName =
        _petValue(
      pets[index],
      [
        'name',
        'petName',
      ],
    );

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Delete Pet?',
          ),
          content: Text(
            petName.isEmpty
                ? 'Are you sure you want to delete this pet?'
                : 'Remove $petName from your profile?',
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
                style: TextStyle(
                  color: Colors.red,
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

    final List<Map<String, dynamic>>
        updatedPets =
        List<Map<String, dynamic>>.from(
      pets,
    );

    updatedPets.removeAt(index);

    await _savePets(
      updatedPets,
      successMessage:
          'Pet deleted successfully.',
    );
  }

  // ============================================================
  // PET EDITOR
  // ============================================================

  Future<void> _showPetEditor({
    int? index,
    Map<String, dynamic>? existingPet,
  }) async {
    final TextEditingController nameController =
        TextEditingController(
      text: existingPet == null
          ? ''
          : _petValue(
              existingPet,
              [
                'name',
                'petName',
              ],
            ),
    );

    String? selectedAge =
        existingPet == null
            ? null
            : _petValue(
                existingPet,
                [
                  'age',
                  'petAge',
                ],
              );

    String? selectedBreed =
        existingPet == null
            ? null
            : _petValue(
                existingPet,
                [
                  'breed',
                  'petBreed',
                ],
              );

    String? selectedBehaviour =
        existingPet == null
            ? null
            : _petValue(
                existingPet,
                [
                  'behaviour',
                  'behavior',
                  'petBehaviour',
                ],
              );

    final List<String> ages = [
      'Puppy',
      '1 Year',
      '2 Years',
      '3 Years',
      '4 Years',
      '5 Years',
      '6 Years',
      '7 Years',
      '8 Years',
      '9 Years',
      '10+ Years',
    ];

    final List<String> breeds = [
      'Labrador Retriever',
      'Golden Retriever',
      'German Shepherd',
      'Beagle',
      'Pug',
      'Rottweiler',
      'Shih Tzu',
      'Pomeranian',
      'Husky',
      'Indie',
      'Other',
    ];

    final List<String> behaviours = [
      'Friendly',
      'Playful',
      'Calm',
      'Active',
      'Shy',
      'Aggressive',
      'Anxious',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom:
                      MediaQuery.of(context)
                              .viewInsets
                              .bottom +
                          20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration:
                                BoxDecoration(
                              color:
                                  lightOrange,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                13,
                              ),
                            ),
                            child:
                                const Icon(
                              Icons.pets_rounded,
                              color: orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              index == null
                                  ? 'Add Pet'
                                  : 'Edit Pet',
                              style:
                                  const TextStyle(
                                fontSize: 21,
                                fontWeight:
                                    FontWeight.w800,
                                color: navy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                sheetContext,
                              );
                            },
                            icon:
                                const Icon(
                              Icons.close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _EditorField(
                        controller:
                            nameController,
                        label: 'Pet Name',
                        hint: 'Enter pet name',
                        icon:
                            Icons.pets_outlined,
                      ),

                      const SizedBox(height: 14),

                      _EditorPicker(
                        label: 'Age',
                        value: selectedAge,
                        icon:
                            Icons.cake_outlined,
                        onTap: () async {
                          final String? result =
                              await _selectValue(
                            title:
                                'Choose Pet Age',
                            items: ages,
                            selected:
                                selectedAge,
                          );

                          if (result != null) {
                            setSheetState(() {
                              selectedAge =
                                  result;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      _EditorPicker(
                        label: 'Breed',
                        value: selectedBreed,
                        icon:
                            Icons.pets_outlined,
                        onTap: () async {
                          final String? result =
                              await _selectValue(
                            title:
                                'Choose Breed',
                            items: breeds,
                            selected:
                                selectedBreed,
                          );

                          if (result != null) {
                            setSheetState(() {
                              selectedBreed =
                                  result;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      _EditorPicker(
                        label: 'Behaviour',
                        value:
                            selectedBehaviour,
                        icon:
                            Icons
                                .favorite_border_rounded,
                        onTap: () async {
                          final String? result =
                              await _selectValue(
                            title:
                                'Choose Behaviour',
                            items: behaviours,
                            selected:
                                selectedBehaviour,
                          );

                          if (result != null) {
                            setSheetState(() {
                              selectedBehaviour =
                                  result;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              isSavingPet
                                  ? null
                                  : () async {
                                      final String
                                          name =
                                          nameController
                                              .text
                                              .trim();

                                      if (name.isEmpty) {
                                        _showMessage(
                                          'Please enter pet name.',
                                        );
                                        return;
                                      }

                                      if (selectedAge ==
                                              null ||
                                          selectedAge!
                                              .isEmpty) {
                                        _showMessage(
                                          'Please choose pet age.',
                                        );
                                        return;
                                      }

                                      if (selectedBreed ==
                                              null ||
                                          selectedBreed!
                                              .isEmpty) {
                                        _showMessage(
                                          'Please choose pet breed.',
                                        );
                                        return;
                                      }

                                      if (selectedBehaviour ==
                                              null ||
                                          selectedBehaviour!
                                              .isEmpty) {
                                        _showMessage(
                                          'Please choose pet behaviour.',
                                        );
                                        return;
                                      }

                                      final Map<
                                              String,
                                              dynamic>
                                          pet =
                                          <String,
                                              dynamic>{
                                        'name':
                                            name,
                                        'age':
                                            selectedAge,
                                        'breed':
                                            selectedBreed,
                                        'behaviour':
                                            selectedBehaviour,
                                      };

                                      final List<
                                              Map<String,
                                                  dynamic>>
                                          updatedPets =
                                          List<
                                              Map<String,
                                                  dynamic>>.from(
                                        pets,
                                      );

                                      if (index == null) {
                                        if (updatedPets
                                                .length >=
                                            3) {
                                          _showMessage(
                                            'Maximum 3 pets can be added.',
                                          );
                                          return;
                                        }

                                        updatedPets.add(
                                          pet,
                                        );
                                      } else {
                                        updatedPets[index] =
                                            pet;
                                      }

                                      final bool
                                          saved =
                                          await _savePets(
                                        updatedPets,
                                        successMessage:
                                            index == null
                                                ? 'Pet added successfully.'
                                                : 'Pet updated successfully.',
                                      );

                                      if (saved &&
                                          sheetContext
                                              .mounted) {
                                        Navigator.pop(
                                          sheetContext,
                                        );
                                      }
                                    },
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                orange,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              isSavingPet
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : Text(
                                      index == null
                                          ? 'Add Pet'
                                          : 'Save Changes',
                                      style:
                                          const TextStyle(
                                        fontSize: 15,
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
      },
    );

    nameController.dispose();
  }

  // ============================================================
  // SELECT VALUE
  // ============================================================

  Future<String?> _selectValue({
    required String title,
    required List<String> items,
    required String? selected,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(18),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child:
                      ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        items.length,
                    itemBuilder:
                        (_, index) {
                      final String item =
                          items[index];

                      final bool
                          isSelected =
                          item ==
                              selected;

                      return ListTile(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        leading:
                            Icon(
                          isSelected
                              ? Icons
                                  .check_circle_rounded
                              : Icons
                                  .radio_button_unchecked,
                          color:
                              isSelected
                                  ? orange
                                  : Colors.grey,
                        ),
                        title:
                            Text(
                          item,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(
                            context,
                            item,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SAVE PETS
  // ============================================================

  Future<bool> _savePets(
    List<Map<String, dynamic>>
        updatedPets, {
    required String successMessage,
  }) async {
    if (ownerId.trim().isEmpty) {
      _showMessage(
        'Owner ID was not found.',
      );
      return false;
    }

    if (updatedPets.isEmpty) {
      _showMessage(
        'At least one pet is required.',
      );
      return false;
    }

    if (updatedPets.length > 3) {
      _showMessage(
        'Maximum 3 pets can be added.',
      );
      return false;
    }

    setState(() {
      isSavingPet = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('owners')
          .doc(ownerId)
          .set(
        <String, dynamic>{
          'pets': updatedPets,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return false;

      setState(() {
        pets =
            List<Map<String, dynamic>>.from(
          updatedPets,
        );
      });

      _showMessage(
        successMessage,
      );

      return true;
    } on FirebaseException catch (e) {
      if (mounted) {
        _showMessage(
          e.message ??
              'Could not save pet details.',
        );
      }

      return false;
    } catch (e) {
      debugPrint(
        'Save Pets Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Could not save pet details.',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSavingPet = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon:
              const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title:
            const Row(
          children: [
            Icon(
              Icons.person_rounded,
              size: 21,
            ),
            SizedBox(width: 7),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: orange,
                  strokeWidth: 2.5,
                ),
              )
            : RefreshIndicator(
                color: orange,
                onRefresh:
                    _loadOwnerProfile,
                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    15,
                    12,
                    15,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ProfileCard(
                        ownerName: ownerName,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const _SectionTitle(
                        title:
                            'Owner Information',
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      OwnerInfoCard(
                        ownerId: ownerId,
                        mobileNumber:
                            mobileNumber,
                        ownerName:
                            ownerName,
                        ownerDob:
                            ownerDob,
                        ownerGender:
                            ownerGender,
                        memberSince:
                            memberSince,
                        isActive:
                            isActive,
                        onChangeMobile:
                            _openChangeMobile,
                        onCopyOwnerId:
                            _copyOwnerId,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Row(
                        children: [
                          const Expanded(
                            child:
                                _SectionTitle(
                              title:
                                  'Address',
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                _openAddressEditor,
                            style:
                                TextButton
                                    .styleFrom(
                              foregroundColor:
                                  orange,
                              padding:
                                  EdgeInsets.zero,
                            ),
                            icon:
                                const Icon(
                              Icons
                                  .edit_outlined,
                              size: 17,
                            ),
                            label:
                                const Text(
                              'Edit',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AddressCard(
                        flatHouseNo:
                            flatHouseNo,
                        streetRoad:
                            streetRoad,
                        landmark:
                            landmark,
                        hasLocation:
                            _hasConnectedLocation,
                        isConnecting:
                            isConnectingLocation,
                        onConnectLocation:
                            _updateCurrentLocation,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Row(
                        children: [
                          const Expanded(
                            child:
                                _SectionTitle(
                              title:
                                  'Pet Details',
                            ),
                          ),
                          if (pets.isNotEmpty)
                            Text(
                              '${pets.length}/3 Pets',
                              style:
                                  const TextStyle(
                                color: orange,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      if (pets.isEmpty)
                        _AddPetLargeButton(
                          onPressed:
                              _addPet,
                        )
                      else
                        ...List.generate(
                          pets.length,
                          (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                bottom: 12,
                              ),
                              child:
                                  PetDetailsCard(
                                pet:
                                    pets[index],
                                index:
                                    index,
                                onEdit:
                                    () =>
                                        _editPet(
                                  index,
                                ),
                                onDelete:
                                    () =>
                                        _deletePet(
                                  index,
                                ),
                              ),
                            );
                          },
                        ),

                      if (pets.isNotEmpty &&
                          pets.length < 3)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 2,
                          ),
                          child:
                              _AddPetLargeButton(
                            onPressed:
                                _addPet,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 19,
          width: 4,
          decoration:
              BoxDecoration(
            color: orange,
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style:
              const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ADD PET BUTTON
// ============================================================

class _AddPetLargeButton
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddPetLargeButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child:
          OutlinedButton.icon(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          foregroundColor: orange,
          side:
              const BorderSide(
            color: orange,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        icon:
            const Icon(
          Icons.add_rounded,
        ),
        label:
            const Text(
          'Add Pet',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADDRESS EDITOR FIELD
// ============================================================

class _AddressEditorField
    extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _AddressEditorField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization:
          TextCapitalization.sentences,
      decoration:
          InputDecoration(
        hintText: hint,
        prefixIcon:
            const Icon(
          Icons.edit_location_outlined,
          color: orange,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF7F7F7),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: orange,
            width: 1.3,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EDITOR FIELD
// ============================================================

class _EditorField
    extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const _EditorField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization:
          TextCapitalization.words,
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(
          icon,
          color: orange,
        ),
        filled: true,
        fillColor:
            const Color(0xFFF8F8F8),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }
}

// ============================================================
// EDITOR PICKER
// ============================================================

class _EditorPicker
    extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const _EditorPicker({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF8F8F8),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value == null ||
                            value!.isEmpty
                        ? 'Choose $label'
                        : value!,
                    style:
                        TextStyle(
                      fontSize: 14,
                      color: value == null ||
                              value!.isEmpty
                          ? Colors.grey
                          : navy,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
