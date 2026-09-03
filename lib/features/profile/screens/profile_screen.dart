// File:
// lib/features/profile/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../screens/address_screen.dart';
import '../change_mobile/change_mobile_flow.dart';
import '../widgets/address_card.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/pet_details_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  String _ownerId = '';
  String _ownerName = '';
  String _mobileNumber = '';
  String _ownerDob = '';
  String _ownerGender = '';
  String _memberSince = '';

  bool _isActive = true;

  // ============================================================
  // ADDRESS
  // ============================================================

  String _addressLine1 = '';
  String _streetRoad = '';
  String _area = '';
  String _city = '';
  String _state = '';
  String _pincode = '';

  // ============================================================
  // PETS
  // ============================================================

  List<Map<String, dynamic>> _pets =
      <Map<String, dynamic>>[];

  static const int _maximumPets = 3;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // FIND CURRENT OWNER DOCUMENT
  //
  // Canonical collection = owners
  //
  // Document ID is ownerId, NOT necessarily Firebase UID.
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _findOwnerDocument(
    String uid,
  ) async {
    final FirebaseFirestore firestore =
        FirebaseFirestore.instance;

    // ----------------------------------------------------------
    // 1. Find by authUid
    // ----------------------------------------------------------

    final QuerySnapshot<Map<String, dynamic>>
        query =
        await firestore
            .collection('owners')
            .where(
              'authUid',
              isEqualTo: uid,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    // ----------------------------------------------------------
    // 2. Direct UID document fallback
    //
    // Some older owner documents may use UID as document ID.
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>>
        direct =
        await firestore
            .collection('owners')
            .doc(uid)
            .get();

    if (direct.exists) {
      return direct;
    }

    return null;
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final String uid =
          user.uid.trim();

      final DocumentSnapshot<
              Map<String, dynamic>>?
          ownerDoc =
          await _findOwnerDocument(uid);

      // ========================================================
      // OWNER NOT FOUND
      // ========================================================

      if (ownerDoc == null ||
          !ownerDoc.exists) {
        if (!mounted) {
          return;
        }

        setState(() {
          _ownerId = uid;

          _ownerName =
              _firebaseName(user);

          _mobileNumber =
              _firebasePhone(user);

          _ownerDob = '';
          _ownerGender = '';
          _memberSince = '';

          _addressLine1 = '';
          _streetRoad = '';
          _area = '';
          _city = '';
          _state = '';
          _pincode = '';

          _pets =
              <Map<String, dynamic>>[];

          _isActive = true;

          _isLoading = false;
        });

        return;
      }

      // ========================================================
      // FIRESTORE DATA
      // ========================================================

      final Map<String, dynamic> data =
          ownerDoc.data() ??
              <String, dynamic>{};

      // ========================================================
      // OWNER ID
      // ========================================================

      final String ownerId =
          _firstNonEmpty([
        data['ownerId'],
        ownerDoc.id,
        uid,
      ]);

      // ========================================================
      // OWNER NAME
      // ========================================================

      final String ownerName =
          _firstNonEmpty([
        data['ownerName'],
        data['fullName'],
        data['name'],
        data['displayName'],
        user.displayName,
      ]);

      // ========================================================
      // MOBILE
      // ========================================================

      final String mobile =
          _firstNonEmpty([
        data['mainPhone'],
        data['phone'],
        data['phoneNumber'],
        data['mobileNumber'],
        data['mobile'],
        user.phoneNumber,
      ]);

      // ========================================================
      // DOB
      // ========================================================

      final String dob =
          _firstNonEmpty([
        data['dob'],
        data['dateOfBirth'],
        data['ownerDob'],
      ]);

      // ========================================================
      // GENDER
      // ========================================================

      final String gender =
          _firstNonEmpty([
        data['gender'],
        data['ownerGender'],
      ]);

      // ========================================================
      // MEMBER SINCE
      // ========================================================

      final String memberSince =
          _formatMemberSince(
        data['createdAt'],
      );

      // ========================================================
      // ADDRESS
      // ========================================================

      final Map<String, dynamic>
          address =
          _readCanonicalAddress(data);

      String addressLine1 =
          _firstNonEmpty([
        address['flatNumber'],
        address['flatHouseNo'],
        address['houseNo'],
        address['houseNumber'],
      ]);

      String streetRoad =
          _firstNonEmpty([
        address['addressLine1'],
        address['streetRoad'],
        address['street'],
        address['road'],
      ]);

      final String addressLine2 =
          _stringValue(
        address['addressLine2'],
      );

      if (addressLine2.isNotEmpty) {
        if (streetRoad.isEmpty) {
          streetRoad = addressLine2;
        } else if (!streetRoad
            .contains(addressLine2)) {
          streetRoad =
              '$streetRoad, $addressLine2';
        }
      }

      String area =
          _firstNonEmpty([
        address['area'],
        address['subLocality'],
        address['locality'],
      ]);

      String city =
          _firstNonEmpty([
        address['city'],
        address['town'],
      ]);

      String state =
          _firstNonEmpty([
        address['state'],
        address['administrativeArea'],
      ]);

      String pincode =
          _firstNonEmpty([
        address['pincode'],
        address['Pincode'],
        address['postalCode'],
      ]);

      // ========================================================
      // SAVED ADDRESS COMPATIBILITY
      //
      // Canonical address above remains primary.
      // savedAddresses is only a compatibility fallback.
      // ========================================================

      if (addressLine1.isEmpty ||
          streetRoad.isEmpty ||
          area.isEmpty ||
          city.isEmpty ||
          state.isEmpty ||
          pincode.isEmpty) {
        final Map<String, dynamic>?
            savedAddress =
            _getSavedAddress(data);

        if (savedAddress != null) {
          if (addressLine1.isEmpty) {
            addressLine1 =
                _firstNonEmpty([
              savedAddress['flatNumber'],
              savedAddress['flatHouseNo'],
              savedAddress['flat'],
              savedAddress['houseNo'],
              savedAddress['houseNumber'],
            ]);
          }

          if (streetRoad.isEmpty) {
            streetRoad =
                _firstNonEmpty([
              savedAddress['addressLine1'],
              savedAddress['streetRoad'],
              savedAddress['street'],
              savedAddress['road'],
              savedAddress['addressLine2'],
            ]);
          }

          if (area.isEmpty) {
            area =
                _firstNonEmpty([
              savedAddress['area'],
              savedAddress['subLocality'],
              savedAddress['locality'],
            ]);
          }

          if (city.isEmpty) {
            city =
                _firstNonEmpty([
              savedAddress['city'],
              savedAddress['town'],
            ]);
          }

          if (state.isEmpty) {
            state =
                _firstNonEmpty([
              savedAddress['state'],
              savedAddress['administrativeArea'],
            ]);
          }

          if (pincode.isEmpty) {
            pincode =
                _firstNonEmpty([
              savedAddress['pincode'],
              savedAddress['Pincode'],
              savedAddress['postalCode'],
            ]);
          }
        }
      }

      // ========================================================
      // PETS
      // ========================================================

      final List<Map<String, dynamic>> pets =
          _readPets(data['pets']);

      // ========================================================
      // ACTIVE STATUS
      // ========================================================

      final bool active =
          _boolValue(
        data['isActive'],
        fallback: true,
      );

      // ========================================================
      // SET STATE
      // ========================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _ownerId = ownerId;

        _ownerName =
            ownerName.isNotEmpty
                ? ownerName
                : 'Owner';

        _mobileNumber =
            mobile.isNotEmpty
                ? mobile
                : 'Not available';

        _ownerDob = dob;
        _ownerGender = gender;
        _memberSince = memberSince;

        _addressLine1 =
            addressLine1;

        _streetRoad =
            streetRoad;

        _area = area;
        _city = city;
        _state = state;
        _pincode = pincode;

        _pets = pets;

        _isActive = active;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Profile Load Error: $e',
      );

      if (!mounted) {
        return;
      }

      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      setState(() {
        _ownerId =
            currentUser?.uid ?? '';

        _ownerName =
            _firebaseName(currentUser);

        _mobileNumber =
            _firebasePhone(currentUser);

        _isLoading = false;
      });

      _showMessage(
        'Could not load complete profile information.',
      );
    }
  }

  // ============================================================
  // READ CANONICAL ADDRESS
  // ============================================================

  Map<String, dynamic> _readCanonicalAddress(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['address'];

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return <String, dynamic>{};
  }

  // ============================================================
  // GET SAVED ADDRESS
  // ============================================================

  Map<String, dynamic>? _getSavedAddress(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['savedAddresses'];

    if (value is! List ||
        value.isEmpty) {
      return null;
    }

    for (final dynamic item in value) {
      if (item is Map) {
        final Map<String, dynamic>
            address =
            Map<String, dynamic>.from(
          item,
        );

        if (_hasAddressData(address)) {
          return address;
        }
      }
    }

    return null;
  }

  // ============================================================
  // CHECK ADDRESS DATA
  // ============================================================

  bool _hasAddressData(
    Map<String, dynamic> address,
  ) {
    final String combined =
        _firstNonEmpty([
      address['flatNumber'],
      address['addressLine1'],
      address['addressLine2'],
      address['area'],
      address['city'],
      address['state'],
      address['pincode'],
    ]);

    return combined.isNotEmpty;
  }

  // ============================================================
  // READ PETS
  // ============================================================

  List<Map<String, dynamic>> _readPets(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>>
        result =
        <Map<String, dynamic>>[];

    for (final dynamic item in value) {
      if (item is Map) {
        result.add(
          Map<String, dynamic>.from(
            item,
          ),
        );
      }
    }

    return result;
  }

  // ============================================================
  // ADD PET
  // ============================================================

  Future<void> _addPet() async {
    if (_pets.length >= _maximumPets) {
      _showMessage(
        'Maximum 3 pets allowed.',
      );
      return;
    }

    final TextEditingController
        nameController =
        TextEditingController();

    final TextEditingController
        ageController =
        TextEditingController();

    final TextEditingController
        breedController =
        TextEditingController();

    final TextEditingController
        behaviourController =
        TextEditingController();

    final GlobalKey<FormState>
        formKey =
        GlobalKey<FormState>();

    final bool? saved =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppColors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(26),
        ),
      ),
      builder:
          (BuildContext sheetContext) {
        return Padding(
          padding:
              EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom +
                20,
          ),
          child:
              SingleChildScrollView(
            child:
                Form(
              key: formKey,
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child:
                        Container(
                      width: 42,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.navy
                                .withValues(
                          alpha: 0.15,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.orange
                                  .withValues(
                            alpha: 0.12,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons.pets_rounded,
                          color:
                              AppColors.orange,
                          size: 25,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Add Pet',
                              style:
                                  TextStyle(
                                color:
                                    AppColors.navy,
                                fontSize:
                                    20,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            SizedBox(
                              height: 2,
                            ),
                            Text(
                              'Add your pet details',
                              style:
                                  TextStyle(
                                color:
                                    Colors.grey,
                                fontSize:
                                    13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  _petField(
                    controller:
                        nameController,
                    label:
                        'Pet Name',
                    icon:
                        Icons.pets_rounded,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        ageController,
                    label:
                        'Age',
                    icon:
                        Icons.cake_outlined,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        breedController,
                    label:
                        'Breed',
                    icon:
                        Icons.category_outlined,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        behaviourController,
                    label:
                        'Behaviour',
                    icon:
                        Icons.psychology_outlined,
                    requiredField:
                        true,
                    maxLines:
                        2,
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height:
                        52,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          () async {
                        if (!formKey
                            .currentState!
                            .validate()) {
                          return;
                        }

                        final bool result =
                            await _saveNewPet(
                          name:
                              nameController
                                  .text,
                          age:
                              ageController
                                  .text,
                          breed:
                              breedController
                                  .text,
                          behaviour:
                              behaviourController
                                  .text,
                        );

                        if (result &&
                            sheetContext
                                .mounted) {
                          Navigator.of(
                            sheetContext,
                          ).pop(true);
                        }
                      },
                      icon:
                          const Icon(
                        Icons
                            .add_rounded,
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
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.orange,
                        foregroundColor:
                            AppColors.white,
                        elevation:
                            0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
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

    nameController.dispose();
    ageController.dispose();
    breedController.dispose();
    behaviourController.dispose();

    if (saved == true && mounted) {
      await _loadProfile();
    }
  }

  // ============================================================
  // PET FIELD
  // ============================================================

  Widget _petField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool requiredField,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization:
          TextCapitalization.sentences,
      validator: (String? value) {
        if (!requiredField) {
          return null;
        }

        if (value == null ||
            value.trim().isEmpty) {
          return '$label is required';
        }

        return null;
      },
      decoration:
          InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(
          icon,
          color:
              AppColors.orange,
        ),
        filled: true,
        fillColor:
            AppColors.background,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.orange,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE NEW PET
  // ============================================================

  Future<bool> _saveNewPet({
    required String name,
    required String age,
    required String breed,
    required String behaviour,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
      );
      return false;
    }

    try {
      final String uid =
          user.uid.trim();

      final DocumentSnapshot<
              Map<String, dynamic>>?
          ownerDoc =
          await _findOwnerDocument(uid);

      if (ownerDoc == null ||
          !ownerDoc.exists) {
        _showMessage(
          'Owner profile not found.',
        );
        return false;
      }

      final Map<String, dynamic>
          ownerData =
          ownerDoc.data() ??
              <String, dynamic>{};

      final List<Map<String, dynamic>>
          currentPets =
          _readPets(
        ownerData['pets'],
      );

      if (currentPets.length >=
          _maximumPets) {
        _showMessage(
          'Maximum 3 pets allowed.',
        );
        return false;
      }

      final Map<String, dynamic>
          newPet =
          <String, dynamic>{
        'name': name.trim(),
        'age': age.trim(),
        'breed': breed.trim(),
        'behaviour':
            behaviour.trim(),
      };

      currentPets.add(newPet);

      await ownerDoc.reference
          .set(
        {
          'pets': currentPets,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return true;
      }

      setState(() {
        _pets = currentPets;
      });

      _showMessage(
        'Pet added successfully.',
      );

      return true;
    } catch (e) {
      debugPrint(
        'Add Pet Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to add pet.',
        );
      }

      return false;
    }
  }

  // ============================================================
  // PET EDIT
  // ============================================================

  Future<void> _editPet(
    int index,
  ) async {
    if (index < 0 ||
        index >= _pets.length) {
      return;
    }

    final Map<String, dynamic>
        existing =
        _pets[index];

    final TextEditingController
        nameController =
        TextEditingController(
      text: _firstNonEmpty([
        existing['name'],
        existing['petName'],
      ]),
    );

    final TextEditingController
        ageController =
        TextEditingController(
      text: _firstNonEmpty([
        existing['age'],
        existing['petAge'],
      ]),
    );

    final TextEditingController
        breedController =
        TextEditingController(
      text: _firstNonEmpty([
        existing['breed'],
        existing['petBreed'],
      ]),
    );

    final TextEditingController
        behaviourController =
        TextEditingController(
      text: _firstNonEmpty([
        existing['behaviour'],
        existing['behavior'],
        existing['petBehaviour'],
      ]),
    );

    final GlobalKey<FormState>
        formKey =
        GlobalKey<FormState>();

    final bool? saved =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppColors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(26),
        ),
      ),
      builder:
          (BuildContext sheetContext) {
        return Padding(
          padding:
              EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(
                  sheetContext,
                ).viewInsets.bottom +
                20,
          ),
          child:
              SingleChildScrollView(
            child:
                Form(
              key: formKey,
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child:
                        Container(
                      width: 42,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.navy
                                .withValues(
                          alpha: 0.15,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.orange
                                  .withValues(
                            alpha: 0.12,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons.edit_rounded,
                          color:
                              AppColors.orange,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const Text(
                        'Edit Pet',
                        style:
                            TextStyle(
                          color:
                              AppColors.navy,
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  _petField(
                    controller:
                        nameController,
                    label:
                        'Pet Name',
                    icon:
                        Icons.pets_rounded,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        ageController,
                    label:
                        'Age',
                    icon:
                        Icons.cake_outlined,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        breedController,
                    label:
                        'Breed',
                    icon:
                        Icons.category_outlined,
                    requiredField:
                        true,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  _petField(
                    controller:
                        behaviourController,
                    label:
                        'Behaviour',
                    icon:
                        Icons.psychology_outlined,
                    requiredField:
                        true,
                    maxLines:
                        2,
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height:
                        52,
                    child:
                        ElevatedButton(
                      onPressed:
                          () async {
                        if (!formKey
                            .currentState!
                            .validate()) {
                          return;
                        }

                        final bool result =
                            await _updatePet(
                          index:
                              index,
                          name:
                              nameController
                                  .text,
                          age:
                              ageController
                                  .text,
                          breed:
                              breedController
                                  .text,
                          behaviour:
                              behaviourController
                                  .text,
                        );

                        if (result &&
                            sheetContext
                                .mounted) {
                          Navigator.of(
                            sheetContext,
                          ).pop(true);
                        }
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.orange,
                        foregroundColor:
                            AppColors.white,
                        elevation:
                            0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Save Changes',
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

    nameController.dispose();
    ageController.dispose();
    breedController.dispose();
    behaviourController.dispose();

    if (saved == true && mounted) {
      await _loadProfile();
    }
  }

  // ============================================================
  // UPDATE PET
  // ============================================================

  Future<bool> _updatePet({
    required int index,
    required String name,
    required String age,
    required String breed,
    required String behaviour,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login again.',
      );
      return false;
    }

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>?
          ownerDoc =
          await _findOwnerDocument(
        user.uid.trim(),
      );

      if (ownerDoc == null ||
          !ownerDoc.exists) {
        _showMessage(
          'Owner profile not found.',
        );
        return false;
      }

      final Map<String, dynamic>
          ownerData =
          ownerDoc.data() ??
              <String, dynamic>{};

      final List<Map<String, dynamic>>
          updatedPets =
          _readPets(
        ownerData['pets'],
      );

      if (index < 0 ||
          index >= updatedPets.length) {
        _showMessage(
          'Pet not found.',
        );
        return false;
      }

      updatedPets[index] =
          <String, dynamic>{
        'name': name.trim(),
        'age': age.trim(),
        'breed': breed.trim(),
        'behaviour':
            behaviour.trim(),
      };

      await ownerDoc.reference
          .set(
        {
          'pets': updatedPets,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return true;
      }

      setState(() {
        _pets = updatedPets;
      });

      _showMessage(
        'Pet updated successfully.',
      );

      return true;
    } catch (e) {
      debugPrint(
        'Update Pet Error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to update pet.',
        );
      }

      return false;
    }
  }

  // ============================================================
  // PET DELETE
  // ============================================================

  Future<void> _deletePet(
    int index,
  ) async {
    if (index < 0 ||
        index >= _pets.length) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppColors.white,
          title: const Text(
            'Delete Pet?',
            style: TextStyle(
              color:
                  AppColors.navy,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this pet from your profile?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color:
                      AppColors.error,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true ||
        !mounted) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>?
          ownerDoc =
          await _findOwnerDocument(
        user.uid.trim(),
      );

      if (ownerDoc == null ||
          !ownerDoc.exists) {
        _showMessage(
          'Owner profile not found.',
        );
        return;
      }

      final Map<String, dynamic>
          ownerData =
          ownerDoc.data() ??
              <String, dynamic>{};

      final List<Map<String, dynamic>>
          updatedPets =
          _readPets(
        ownerData['pets'],
      );

      if (index < 0 ||
          index >= updatedPets.length) {
        _showMessage(
          'Pet not found.',
        );
        return;
      }

      updatedPets.removeAt(index);

      await ownerDoc.reference
          .set(
        {
          'pets': updatedPets,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pets = updatedPets;
      });

      _showMessage(
        'Pet deleted.',
      );
    } catch (e) {
      debugPrint(
        'Delete Pet Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete pet.',
      );
    }
  }

  // ============================================================
  // STRING VALUE
  // ============================================================

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // FIRST NON EMPTY
  // ============================================================

  String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final String text =
          _stringValue(value);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ============================================================
  // FIREBASE USER NAME
  // ============================================================

  String _firebaseName(
    User? user,
  ) {
    final String name =
        user?.displayName?.trim() ??
            '';

    return name.isNotEmpty
        ? name
        : 'Owner';
  }

  // ============================================================
  // FIREBASE PHONE
  // ============================================================

  String _firebasePhone(
    User? user,
  ) {
    final String phone =
        user?.phoneNumber?.trim() ??
            '';

    return phone.isNotEmpty
        ? phone
        : 'Not available';
  }

  // ============================================================
  // BOOL VALUE
  // ============================================================

  bool _boolValue(
    dynamic value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
    }

    return fallback;
  }

  // ============================================================
  // MEMBER SINCE
  // ============================================================

  String _formatMemberSince(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date =
          DateTime.tryParse(value);
    }

    if (date == null) {
      return _stringValue(value);
    }

    return '${_monthName(date.month)} ${date.year}';
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String _monthName(
    int month,
  ) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // ============================================================
  // COPY OWNER ID
  // ============================================================

  void _copyOwnerId() {
    if (_ownerId.trim().isEmpty) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text: _ownerId.trim(),
      ),
    );

    _showMessage(
      'Owner ID copied.',
    );
  }

  // ============================================================
  // CHANGE MOBILE
  // ============================================================

  Future<void> _changeMobile() async {
    final String number =
        _mobileNumber.trim();

    if (number.isEmpty ||
        number == '-' ||
        number == 'Not available') {
      _showMessage(
        'Current mobile number was not found.',
      );
      return;
    }

    final bool? changed =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppColors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(24),
        ),
      ),
      builder:
          (BuildContext context) {
        return ChangeMobileFlow(
          currentNumber:
              number,
          onChanged:
              (_) {},
        );
      },
    );

    if (changed == true &&
        mounted) {
      await _loadProfile();
    }
  }

  // ============================================================
  // EDIT ADDRESS
  // ============================================================

  Future<void> _editAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const AddressScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProfile();
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
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
          ),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              AppColors.navy,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor:
            AppColors.background,
        body: Center(
          child:
              CircularProgressIndicator(
            color:
                AppColors.orange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            AppColors.white,
        foregroundColor:
            AppColors.navy,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color:
                AppColors.navy,
            fontSize: 21,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: SafeArea(
        child:
            RefreshIndicator(
          color:
              AppColors.orange,
          onRefresh:
              _loadProfile,
          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // OWNER INFORMATION
                // ==================================================

                OwnerInfoCard(
                  ownerId:
                      _ownerId,
                  mobileNumber:
                      _mobileNumber,
                  ownerName:
                      _ownerName,
                  ownerDob:
                      _ownerDob,
                  ownerGender:
                      _ownerGender,
                  memberSince:
                      _memberSince,
                  isActive:
                      _isActive,
                  onChangeMobile:
                      _changeMobile,
                  onCopyOwnerId:
                      _copyOwnerId,
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // PET PROFILE
                // ==================================================

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pet Profile',
                        style: TextStyle(
                          color:
                              AppColors.navy,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),

                    if (_pets.length <
                        _maximumPets)
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        onTap:
                            _addPet,
                        child:
                            Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                12,
                            vertical:
                                8,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors.orange
                                    .withValues(
                              alpha:
                                  0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child:
                              const Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .pets_rounded,
                                size:
                                    18,
                                color:
                                    AppColors.orange,
                              ),
                              SizedBox(
                                width:
                                    5,
                              ),
                              Text(
                                'Add Pet',
                                style:
                                    TextStyle(
                                  color:
                                      AppColors.orange,
                                  fontSize:
                                      13,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                // ==================================================
                // PET CARDS
                // ==================================================

                if (_pets.isNotEmpty)
                  ...List.generate(
                    _pets.length,
                    (int index) {
                      final Map<String, dynamic>
                          pet =
                          _pets[index];

                      return Padding(
                        padding:
                            EdgeInsets.only(
                          bottom:
                              index ==
                                      _pets.length -
                                          1
                                  ? 0
                                  : 12,
                        ),
                        child:
                            PetDetailsCard(
                          pet: pet,
                          index:
                              index,
                          onEdit: () {
                            _editPet(
                              index,
                            );
                          },
                          onDelete: () {
                            _deletePet(
                              index,
                            );
                          },
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          18,
                      vertical:
                          22,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                    ),
                    child:
                        Column(
                      children: [
                        Container(
                          width:
                              58,
                          height:
                              58,
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors.orange
                                    .withValues(
                              alpha:
                                  0.10,
                            ),
                            shape:
                                BoxShape.circle,
                          ),
                          child:
                              const Icon(
                            Icons
                                .pets_rounded,
                            color:
                                AppColors.orange,
                            size:
                                30,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const Text(
                          'No pets added yet',
                          style:
                              TextStyle(
                            color:
                                AppColors.navy,
                            fontSize:
                                15,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          'Tap Add Pet to add your first pet.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                13,
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        SizedBox(
                          height:
                              44,
                          child:
                              ElevatedButton
                                  .icon(
                            onPressed:
                                _addPet,
                            icon:
                                const Icon(
                              Icons
                                  .pets_rounded,
                              size:
                                  19,
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
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  AppColors.orange,
                              foregroundColor:
                                  AppColors.white,
                              elevation:
                                  0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // MY ADDRESS
                // ==================================================

                AddressCard(
                  flatHouseNo:
                      _addressLine1,
                  streetRoad:
                      _streetRoad,
                  area:
                      _area,
                  city:
                      _city,
                  state:
                      _state,
                  pincode:
                      _pincode,
                  onEditAddress:
                      _editAddress,
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
