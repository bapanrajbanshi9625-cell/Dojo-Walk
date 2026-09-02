// File: lib/features/profile/screens/profile_screen.dart

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
import '../widgets/profile_card.dart' hide PetDetailsCard;

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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      final String uid = user.uid.trim();

      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      // ========================================================
      // OWNER PROFILE
      //
      // IMPORTANT:
      // AddressScreen uses ownerProfiles.
      // Therefore ProfileScreen also uses ownerProfiles
      // as the primary source.
      // ========================================================

      DocumentSnapshot<Map<String, dynamic>>?
          ownerDoc;

      // --------------------------------------------------------
      // 1. authUid
      // --------------------------------------------------------

      final QuerySnapshot<Map<String, dynamic>>
          authUidQuery =
          await firestore
              .collection('ownerProfiles')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (authUidQuery.docs.isNotEmpty) {
        ownerDoc =
            authUidQuery.docs.first;
      }

      // --------------------------------------------------------
      // 2. ownerAuthUid
      // --------------------------------------------------------

      if (ownerDoc == null) {
        final QuerySnapshot<
            Map<String, dynamic>> ownerAuthQuery =
            await firestore
                .collection('ownerProfiles')
                .where(
                  'ownerAuthUid',
                  isEqualTo: uid,
                )
                .limit(1)
                .get();

        if (ownerAuthQuery.docs.isNotEmpty) {
          ownerDoc =
              ownerAuthQuery.docs.first;
        }
      }

      // --------------------------------------------------------
      // 3. ownerProfiles/{uid}
      // --------------------------------------------------------

      if (ownerDoc == null) {
        final DocumentSnapshot<
            Map<String, dynamic>> directDoc =
            await firestore
                .collection('ownerProfiles')
                .doc(uid)
                .get();

        if (directDoc.exists) {
          ownerDoc = directDoc;
        }
      }

      // ========================================================
      // OPTIONAL LEGACY FALLBACK
      //
      // Only owner information is read from owners if
      // ownerProfiles does not exist.
      //
      // Address still remains ownerProfiles-first.
      // ========================================================

      if (ownerDoc == null) {
        final QuerySnapshot<
            Map<String, dynamic>> ownersQuery =
            await firestore
                .collection('owners')
                .where(
                  'authUid',
                  isEqualTo: uid,
                )
                .limit(1)
                .get();

        if (ownersQuery.docs.isNotEmpty) {
          ownerDoc =
              ownersQuery.docs.first;
        }
      }

      if (ownerDoc == null) {
        final DocumentSnapshot<
            Map<String, dynamic>> legacyDoc =
            await firestore
                .collection('owners')
                .doc(uid)
                .get();

        if (legacyDoc.exists) {
          ownerDoc = legacyDoc;
        }
      }

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

          _addressLine1 = '';
          _streetRoad = '';
          _area = '';
          _city = '';
          _state = '';
          _pincode = '';

          _pets =
              <Map<String, dynamic>>[];

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
        data['id'],
        ownerDoc.id,
        uid,
      ]);

      // ========================================================
      // OWNER NAME
      // ========================================================

      final String ownerName =
          _firstNonEmpty([
        data['ownerName'],
        data['name'],
        data['fullName'],
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
      //
      // PRIMARY SOURCE:
      // savedAddresses[]
      // ========================================================

      Map<String, dynamic>? savedAddress =
          _getSavedAddress(data);

      // ========================================================
      // ADDRESS FROM savedAddresses[]
      // ========================================================

      String addressLine1 = '';
      String streetRoad = '';
      String area = '';
      String city = '';
      String state = '';
      String pincode = '';

      if (savedAddress != null) {
        addressLine1 =
            _firstNonEmpty([
          savedAddress['flatNumber'],
          savedAddress['flatHouseNo'],
          savedAddress['flat'],
          savedAddress['houseNo'],
          savedAddress['houseNumber'],
        ]);

        streetRoad =
            _firstNonEmpty([
          savedAddress['addressLine1'],
          savedAddress['streetRoad'],
          savedAddress['street'],
          savedAddress['road'],
        ]);

        area =
            _firstNonEmpty([
          savedAddress['area'],
          savedAddress['subLocality'],
          savedAddress['locality'],
        ]);

        city =
            _firstNonEmpty([
          savedAddress['city'],
          savedAddress['town'],
        ]);

        state =
            _firstNonEmpty([
          savedAddress['state'],
          savedAddress['administrativeArea'],
        ]);

        pincode =
            _firstNonEmpty([
          savedAddress['pincode'],
          savedAddress['Pincode'],
          savedAddress['postalCode'],
        ]);

        // ------------------------------------------------------
        // If saved address contains a combined address and
        // individual fields are missing, use the combined value
        // in the street field so AddressCard still displays it.
        // ------------------------------------------------------

        if (addressLine1.isEmpty &&
            streetRoad.isEmpty &&
            area.isEmpty &&
            city.isEmpty &&
            state.isEmpty &&
            pincode.isEmpty) {
          streetRoad =
              _firstNonEmpty([
            savedAddress['address'],
            savedAddress['fullAddress'],
            savedAddress['formattedAddress'],
          ]);
        }
      }

      // ========================================================
      // FALLBACK TO PROFILE-LEVEL ADDRESS
      //
      // Supports older records.
      // ========================================================

      if (addressLine1.isEmpty) {
        addressLine1 =
            _firstNonEmpty([
          data['flatNumber'],
          data['flatHouseNo'],
          data['flat'],
          data['houseNo'],
          data['houseNumber'],
        ]);
      }

      if (streetRoad.isEmpty) {
        streetRoad =
            _firstNonEmpty([
          data['addressLine1'],
          data['streetRoad'],
          data['street'],
          data['road'],
        ]);
      }

      if (area.isEmpty) {
        area =
            _firstNonEmpty([
          data['area'],
          data['subLocality'],
          data['locality'],
        ]);
      }

      if (city.isEmpty) {
        city =
            _firstNonEmpty([
          data['city'],
          data['town'],
        ]);
      }

      if (state.isEmpty) {
        state =
            _firstNonEmpty([
          data['state'],
          data['administrativeArea'],
        ]);
      }

      if (pincode.isEmpty) {
        pincode =
            _firstNonEmpty([
          data['pincode'],
          data['Pincode'],
          data['postalCode'],
        ]);
      }

      // ========================================================
      // FULL ADDRESS FALLBACK
      // ========================================================

      if (addressLine1.isEmpty &&
          streetRoad.isEmpty &&
          area.isEmpty &&
          city.isEmpty &&
          state.isEmpty &&
          pincode.isEmpty) {
        final String combined =
            _firstNonEmpty([
          data['address'],
          data['fullAddress'],
          data['formattedAddress'],
        ]);

        if (combined.isNotEmpty) {
          streetRoad = combined;
        }
      }

      // ========================================================
      // PETS
      //
      // Expected:
      // pets: [
      //   {
      //     name: ...,
      //     age: ...,
      //     breed: ...,
      //     behaviour: ...
      //   }
      // ]
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

        _memberSince =
            memberSince;

        // Address
        _addressLine1 =
            addressLine1;

        _streetRoad =
            streetRoad;

        _area =
            area;

        _city =
            city;

        _state =
            state;

        _pincode =
            pincode;

        // Pets
        _pets = pets;

        _isActive =
            active;

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
            _firebaseName(
          currentUser,
        );

        _mobileNumber =
            _firebasePhone(
          currentUser,
        );

        _isLoading = false;
      });

      _showMessage(
        'Could not load complete profile information.',
      );
    }
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
        final Map<String, dynamic> address =
            Map<String, dynamic>.from(
          item,
        );

        final bool valid =
            _hasAddressData(address);

        if (valid) {
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
      address['address'],
      address['fullAddress'],
      address['formattedAddress'],
      address['flatNumber'],
      address['addressLine1'],
      address['addressLine2'],
      address['area'],
      address['city'],
      address['state'],
      address['pincode'],
      address['Pincode'],
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

    final List<Map<String, dynamic>> result =
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
  // PET EDIT
  // ============================================================

  void _editPet(
    int index,
  ) {
    _showMessage(
      'Pet editing is available from Pet Profile.',
    );
  }

  // ============================================================
  // PET DELETE
  //
  // Safe local delete + Firestore update.
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
          (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              AppColors.white,
          title: const Text(
            'Delete Pet?',
            style: TextStyle(
              color: AppColors.navy,
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
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
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
      final String uid =
          user.uid.trim();

      final FirebaseFirestore firestore =
          FirebaseFirestore.instance;

      DocumentReference<
          Map<String, dynamic>>? profileRef;

      // --------------------------------------------------------
      // Find ownerProfiles document exactly like profile loading.
      // --------------------------------------------------------

      final QuerySnapshot<
          Map<String, dynamic>> authQuery =
          await firestore
              .collection('ownerProfiles')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (authQuery.docs.isNotEmpty) {
        profileRef =
            authQuery.docs.first.reference;
      }

      if (profileRef == null) {
        final QuerySnapshot<
            Map<String, dynamic>> ownerAuthQuery =
            await firestore
                .collection('ownerProfiles')
                .where(
                  'ownerAuthUid',
                  isEqualTo: uid,
                )
                .limit(1)
                .get();

        if (ownerAuthQuery.docs.isNotEmpty) {
          profileRef =
              ownerAuthQuery.docs.first.reference;
        }
      }

      if (profileRef == null) {
        final DocumentReference<
            Map<String, dynamic>> directRef =
            firestore
                .collection('ownerProfiles')
                .doc(uid);

        final DocumentSnapshot<
            Map<String, dynamic>> directDoc =
            await directRef.get();

        if (directDoc.exists) {
          profileRef = directRef;
        }
      }

      if (profileRef == null) {
        _showMessage(
          'Owner profile not found.',
        );
        return;
      }

      final List<Map<String, dynamic>> updatedPets =
          List<Map<String, dynamic>>.from(
        _pets,
      );

      updatedPets.removeAt(index);

      await profileRef.update({
        'pets': updatedPets,
      });

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

    return value
        .toString()
        .trim();
  }

  // ============================================================
  // FIRST NON EMPTY
  // ============================================================

  String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final dynamic value
        in values) {
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
        user?.displayName
                ?.trim() ??
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
        user?.phoneNumber
                ?.trim() ??
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
          DateTime.tryParse(
        value,
      );
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
    if (_ownerId
        .trim()
        .isEmpty) {
      return;
    }

    Clipboard.setData(
      ClipboardData(
        text:
            _ownerId.trim(),
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
        number ==
            'Not available') {
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
    await Navigator.of(context)
        .push(
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
                BorderRadius.circular(
              14,
            ),
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
    // ==========================================================
    // LOADING
    // ==========================================================

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

    // ==========================================================
    // SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor:
          AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

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

      // ========================================================
      // BODY
      // ========================================================

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
                const EdgeInsets
                    .fromLTRB(
              16,
              16,
              16,
              30,
            ),
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                // ==================================================
                // PROFILE CARD
                // ==================================================

                ProfileCard(
                  ownerName:
                      _ownerName,
                ),

                const SizedBox(
                  height: 16,
                ),

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

                if (_pets.isNotEmpty) ...[
                  const Text(
                    'Pet Profile',
                    style: TextStyle(
                      color:
                          AppColors.navy,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

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
                          index: index,
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
                  ),

                  const SizedBox(
                    height: 20,
                  ),
                ],

                // ==================================================
                // MY ADDRESS
                //
                // PET PROFILE KE NICHE
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
