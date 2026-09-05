// File:
// lib/features/profile_setup/screens/profile_setup_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/dojo_colors.dart';

import '../models/pet_data.dart';
import '../profile_setup_data.dart';
import '../services/profile_setup_service.dart';

import '../widgets/profile_welcome_card.dart';
import '../widgets/profile_section_card.dart';
import '../widgets/profile_text_field.dart';
import '../widgets/pet_card.dart';
import '../widgets/add_pet_button.dart';
import '../widgets/save_profile_button.dart';

import '../pickers/compact_picker_sheet.dart';
import '../pickers/breed_picker.dart';

import '../../../screens/main_navigation_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
  });

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController ownerController =
      TextEditingController();

  // ============================================================
  // PETS
  // ============================================================

  final List<PetData> pets = <PetData>[
    PetData(),
  ];

  // ============================================================
  // STATE
  // ============================================================

  bool _isSaving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ownerController.dispose();

    for (final PetData pet in pets) {
      pet.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // GET CURRENT FIREBASE USER
  // ============================================================

  User? _getCurrentUser() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    if (user.uid.trim().isEmpty) {
      return null;
    }

    return user;
  }

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  String _normalizePhone(
    String phone,
  ) {
    String value = phone.trim();

    value = value.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    if (value.startsWith('+')) {
      return value;
    }

    if (value.length == 10) {
      return '+91$value';
    }

    if (value.length == 12 &&
        value.startsWith('91')) {
      return '+$value';
    }

    return value;
  }

  // ============================================================
  // GET PHONE NUMBER
  // ============================================================

  Future<String?> _getPhoneNumber(
    User user,
  ) async {
    // ----------------------------------------------------------
    // 1. REAL FIREBASE PHONE
    // ----------------------------------------------------------

    final String firebasePhone =
        user.phoneNumber?.trim() ?? '';

    if (firebasePhone.isNotEmpty) {
      return _normalizePhone(
        firebasePhone,
      );
    }

    // ----------------------------------------------------------
    // 2. TEMPORARY MSG91 VERIFIED PHONE
    // ----------------------------------------------------------

    SharedPreferences? prefs;

    try {
      prefs =
          await SharedPreferences.getInstance();

      final bool otpVerified =
          prefs.getBool(
                'tempOtpVerified',
              ) ??
              false;

      final String tempPhone =
          prefs.getString(
                'tempVerifiedPhone',
              ) ??
              '';

      debugPrint(
        'MSG91 TEMP OTP VERIFIED: $otpVerified',
      );

      debugPrint(
        'MSG91 TEMP PHONE: $tempPhone',
      );

      if (otpVerified &&
          tempPhone.trim().isNotEmpty) {
        final String normalizedPhone =
            _normalizePhone(
          tempPhone,
        );

        debugPrint(
          'PROFILE PHONE FROM MSG91: '
          '$normalizedPhone',
        );

        return normalizedPhone;
      }
    } catch (e) {
      debugPrint(
        'TEMP VERIFIED PHONE READ ERROR: $e',
      );
    }

    // ----------------------------------------------------------
    // 3. TEMPORARY ACCOUNT UID
    // ----------------------------------------------------------

    String tempAccountUid = '';

    try {
      if (prefs == null) {
        prefs =
            await SharedPreferences.getInstance();
      }

      tempAccountUid =
          prefs.getString(
                'tempAccountUid',
              ) ??
              '';

      tempAccountUid =
          tempAccountUid.trim();

      debugPrint(
        'TEMP ACCOUNT UID: $tempAccountUid',
      );
    } catch (e) {
      debugPrint(
        'TEMP ACCOUNT UID READ ERROR: $e',
      );
    }

    // ----------------------------------------------------------
    // 3A. phoneAccounts/{tempAccountUid}
    // ----------------------------------------------------------

    if (tempAccountUid.isNotEmpty) {
      try {
        final DocumentSnapshot<
            Map<String, dynamic>> snapshot =
            await _firestore
                .collection(
                  'phoneAccounts',
                )
                .doc(
                  tempAccountUid,
                )
                .get();

        if (snapshot.exists) {
          final Map<String, dynamic> data =
              snapshot.data() ??
                  <String, dynamic>{};

          final String phone =
              (
                data['phoneNumber'] ??
                    data['phone'] ??
                    data['mainPhone'] ??
                    ''
              )
                  .toString()
                  .trim();

          if (phone.isNotEmpty) {
            final String normalizedPhone =
                _normalizePhone(
              phone,
            );

            debugPrint(
              'PROFILE PHONE FROM TEMP ACCOUNT: '
              '$normalizedPhone',
            );

            return normalizedPhone;
          }
        }
      } on FirebaseException catch (e) {
        debugPrint(
          'TEMP ACCOUNT PHONE READ ERROR: '
          '${e.code} - ${e.message}',
        );
      } catch (e) {
        debugPrint(
          'TEMP ACCOUNT PHONE READ ERROR: $e',
        );
      }
    }

    // ----------------------------------------------------------
    // 4. phoneAccounts/{current Firebase UID}
    // ----------------------------------------------------------

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                'phoneAccounts',
              )
              .doc(
                user.uid,
              )
              .get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        final String phone =
            (
              data['phoneNumber'] ??
                  data['phone'] ??
                  data['mainPhone'] ??
                  ''
            )
                .toString()
                .trim();

        if (phone.isNotEmpty) {
          final String normalizedPhone =
              _normalizePhone(
            phone,
          );

          debugPrint(
            'PROFILE PHONE FROM CURRENT UID: '
            '$normalizedPhone',
          );

          return normalizedPhone;
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'CURRENT UID PHONE READ ERROR: '
        '${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'CURRENT UID PHONE READ ERROR: $e',
      );
    }

    return null;
  }

  // ============================================================
  // ADD PET
  // ============================================================

  void _addPet() {
    if (_isSaving) {
      return;
    }

    if (pets.length >= 3) {
      _showError(
        'Maximum 3 pets can be added.',
      );
      return;
    }

    setState(() {
      pets.add(
        PetData(),
      );
    });
  }

  // ============================================================
  // REMOVE PET
  // ============================================================

  void _removePet(
    int index,
  ) {
    if (_isSaving) {
      return;
    }

    if (pets.length <= 1) {
      _showError(
        'At least one pet is required.',
      );
      return;
    }

    if (index < 0 ||
        index >= pets.length) {
      return;
    }

    final PetData pet =
        pets.removeAt(index);

    pet.dispose();

    setState(() {});
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  bool _validateProfile() {
    final String ownerName =
        ownerController.text.trim();

    if (ownerName.isEmpty) {
      _showError(
        'Please enter owner name.',
      );
      return false;
    }

    if (ownerName.length < 2) {
      _showError(
        'Owner name must contain at least 2 characters.',
      );
      return false;
    }

    if (pets.isEmpty) {
      _showError(
        'Please add at least one pet.',
      );
      return false;
    }

    for (int i = 0;
        i < pets.length;
        i++) {
      final PetData pet =
          pets[i];

      final int number =
          i + 1;

      final String petName =
          pet.nameController.text.trim();

      if (petName.isEmpty) {
        _showError(
          'Please enter Pet $number name.',
        );
        return false;
      }

      final String age =
          pet.age?.trim() ?? '';

      if (age.isEmpty) {
        _showError(
          'Please choose Pet $number age.',
        );
        return false;
      }

      final String breed =
          pet.breed?.trim() ?? '';

      if (breed.isEmpty) {
        _showError(
          'Please choose Pet $number breed.',
        );
        return false;
      }

      final String behaviour =
          pet.behaviour?.trim() ?? '';

      if (behaviour.isEmpty) {
        _showError(
          'Please choose Pet $number behaviour.',
        );
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    if (!_validateProfile()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // 1. CURRENT AUTH USER
      // --------------------------------------------------------

      final User? user =
          _getCurrentUser();

      if (user == null) {
        _showError(
          'Your login session has expired. '
          'Please login again.',
        );
        return;
      }

      debugPrint(
        'PROFILE SETUP UID: ${user.uid}',
      );

      // --------------------------------------------------------
      // 2. VERIFIED PHONE
      // --------------------------------------------------------

      final String? phone =
          await _getPhoneNumber(user);

      if (phone == null ||
          phone.trim().isEmpty) {
        debugPrint(
          'PROFILE SETUP ERROR: '
          'Verified phone was not found.',
        );

        _showError(
          'Verified mobile number was not found. '
          'Please login again.',
        );

        return;
      }

      debugPrint(
        'PROFILE SETUP PHONE: $phone',
      );

      // --------------------------------------------------------
      // 3. SAVE PROFILE
      // --------------------------------------------------------

      await ProfileSetupService.saveProfile(
        ownerName:
            ownerController.text.trim(),
        address:
            '',
        phoneNumber:
            phone,
        pets:
            pets,
        requireLocation:
            false,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // 4. SUCCESS
      // --------------------------------------------------------

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              DojoBrandColors.mint,
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 1,
          ),
          content:
              Text(
            'Profile saved successfully with '
            '${pets.length} '
            '${pets.length == 1 ? 'pet' : 'pets'}.',
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      );

      // --------------------------------------------------------
      // 5. WAIT
      // --------------------------------------------------------

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // 6. MAIN APP
      // --------------------------------------------------------

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'PROFILE AUTH ERROR: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      switch (e.code) {
        case 'operation-not-allowed':
          _showError(
            'Firebase authentication is not enabled.',
          );
          break;

        case 'network-request-failed':
          _showError(
            'Network error. Please check your internet connection.',
          );
          break;

        case 'too-many-requests':
          _showError(
            'Too many attempts. Please try again later.',
          );
          break;

        case 'user-disabled':
          _showError(
            'This account has been disabled.',
          );
          break;

        default:
          final String authMessage =
              e.message?.trim() ?? '';

          _showError(
            authMessage.isNotEmpty
                ? authMessage
                : 'Authentication failed. Please login again.',
          );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'PROFILE FIREBASE ERROR: ${e.code}',
      );

      debugPrint(
        'PROFILE FIREBASE MESSAGE: ${e.message}',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
              'Firebase permission denied. '
              'Please check the Firestore rules.';
          break;

        case 'location-required':
          message =
              'Location permission is required.';
          break;

        case 'location-unavailable':
          message =
              'Current location could not be obtained.';
          break;

        case 'invalid-phone':
          message =
              'Invalid mobile number.';
          break;

        case 'owner-id-missing':
          message =
              'Owner ID could not be created.';
          break;

        case 'owner-name-required':
          message =
              'Owner name is required.';
          break;

        case 'invalid-owner-name':
          message =
              'Owner name must contain at least 2 characters.';
          break;

        case 'minimum-pet-required':
          message =
              'At least one pet is required.';
          break;

        case 'maximum-pets-exceeded':
          message =
              'Maximum 3 pets can be added.';
          break;

        case 'unavailable':
          message =
              'Firebase is temporarily unavailable.';
          break;

        case 'deadline-exceeded':
          message =
              'Firebase request timed out.';
          break;

        default:
          final String firebaseMessage =
              e.message?.trim() ?? '';

          message =
              firebaseMessage.isNotEmpty
                  ? firebaseMessage
                  : 'Could not save profile. Please try again.';
      }

      _showError(message);
    } catch (e) {
      debugPrint(
        'PROFILE SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Something went wrong while saving your profile. '
        'Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            DojoBrandColors.orangeDark,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        content:
            Text(
          message,
          style:
              const TextStyle(
            color:
                Colors.white,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMON PICKER
  // ============================================================

  void _openPicker({
    required String title,
    required IconData icon,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (_) {
        return CompactPickerSheet(
          title:
              title,
          icon:
              icon,
          items:
              items,
          selected:
              selected,
          onSelected:
              onSelected,
        );
      },
    );
  }

  // ============================================================
  // AGE
  // ============================================================

  void _showAgePicker(
    PetData pet,
  ) {
    _openPicker(
      title:
          'Choose Pet Age',
      icon:
          Icons.cake_outlined,
      items:
          ProfileSetupData.ages,
      selected:
          pet.age,
      onSelected:
          (String value) {
        if (!mounted) {
          return;
        }

        setState(() {
          pet.age = value;
        });

        Navigator.of(context).pop();
      },
    );
  }

  // ============================================================
  // BREED
  // ============================================================

  void _showBreedPicker(
    PetData pet,
  ) {
    if (!mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled:
          true,
      useSafeArea:
          true,
      builder: (_) {
        return BreedPicker(
          breeds:
              ProfileSetupData.breeds,
          selectedBreed:
              pet.breed,
          onSelected:
              (String breed) {
            if (!mounted) {
              return;
            }

            setState(() {
              pet.breed =
                  breed;
            });

            Navigator.of(context)
                .pop();
          },
        );
      },
    );
  }

  // ============================================================
  // BEHAVIOUR
  // ============================================================

  void _showBehaviourPicker(
    PetData pet,
  ) {
    _openPicker(
      title:
          'Choose Behaviour',
      icon:
          Icons.favorite_border_rounded,
      items:
          ProfileSetupData.behaviours,
      selected:
          pet.behaviour,
      onSelected:
          (String value) {
        if (!mounted) {
          return;
        }

        setState(() {
          pet.behaviour =
              value;
        });

        Navigator.of(context)
            .pop();
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          DojoLightColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar:
          AppBar(
        backgroundColor:
            DojoBrandColors.orange,
        foregroundColor:
            Colors.white,
        elevation:
            0,
        automaticallyImplyLeading:
            false,
        title:
            const Row(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 26,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Profile Setup',
              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body:
          SafeArea(
        child:
            SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            35,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const ProfileWelcomeCard(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // OWNER
              // ==================================================

              Text(
                'Owner Information',
                style:
                    TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      DojoLightColors.text,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              ProfileSectionCard(
                child:
                    ProfileTextField(
                  controller:
                      ownerController,
                  label:
                      'Owner Name',
                  hint:
                      'Enter owner name',
                  icon:
                      Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // PET INFORMATION
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        Text(
                      'Pet Information',
                      style:
                          TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            DojoLightColors.text,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          DojoBrandColors
                              .orangeLight,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        Text(
                      '${pets.length}/3 Pets',
                      style:
                          const TextStyle(
                        color:
                            DojoBrandColors.orange,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              // ==================================================
              // PET CARDS
              // ==================================================

              ...List.generate(
                pets.length,
                (int index) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child:
                        PetCard(
                      pet:
                          pets[index],
                      index:
                          index,
                      totalPets:
                          pets.length,
                      onRemove:
                          () =>
                              _removePet(
                            index,
                          ),
                      onAgeTap:
                          () =>
                              _showAgePicker(
                            pets[index],
                          ),
                      onBreedTap:
                          () =>
                              _showBreedPicker(
                            pets[index],
                          ),
                      onBehaviourTap:
                          () =>
                              _showBehaviourPicker(
                            pets[index],
                          ),
                    ),
                  );
                },
              ),

              // ==================================================
              // ADD PET
              // ==================================================

              if (pets.length < 3)
                AddPetButton(
                  onPressed:
                      _addPet,
                ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // SAVE
              // ==================================================

              SaveProfileButton(
                isSaving:
                    _isSaving,
                onPressed:
                    _saveProfile,
              ),

              const SizedBox(
                height: 12,
              ),

              Center(
                child:
                    Text(
                  'Your profile information is securely stored.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        DojoInputColors
                            .lightHint,
                    fontSize:
                        11,
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
