import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/dojo_colors.dart';

import '../models/pet_data.dart';
import '../screens/main_navigation_screen.dart';

import '../features/profile_setup/profile_setup_data.dart';
import '../features/profile_setup/services/profile_setup_service.dart';

import '../features/profile_setup/widgets/profile_welcome_card.dart';
import '../features/profile_setup/widgets/profile_section_card.dart';
import '../features/profile_setup/widgets/profile_text_field.dart';
import '../features/profile_setup/widgets/pet_card.dart';
import '../features/profile_setup/widgets/add_pet_button.dart';
import '../features/profile_setup/widgets/address_field.dart';
import '../features/profile_setup/widgets/save_profile_button.dart';

import '../features/profile_setup/pickers/compact_picker_sheet.dart';
import '../features/profile_setup/pickers/breed_picker.dart';

// ============================================================
// DOJO THEME COLORS
// ============================================================

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
  // CONTROLLERS
  // ============================================================

  final TextEditingController ownerController =
      TextEditingController();

  final TextEditingController addressController =
      TextEditingController();

  // ============================================================
  // PETS
  // ============================================================

  final List<PetData> pets = [
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
    addressController.dispose();

    for (final pet in pets) {
      pet.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // ADD PET
  // ============================================================

  void _addPet() {
    if (pets.length >= 3) {
      _showError(
        'Maximum 3 pets can be added.',
      );
      return;
    }

    setState(() {
      pets.add(PetData());
    });
  }

  // ============================================================
  // REMOVE PET
  // ============================================================

  void _removePet(int index) {
    if (pets.length <= 1) {
      _showError(
        'At least one pet is required.',
      );
      return;
    }

    final PetData pet =
        pets.removeAt(index);

    pet.dispose();

    setState(() {});
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _validateProfile() {
    // ----------------------------------------------------------
    // OWNER NAME
    // ----------------------------------------------------------

    if (ownerController.text.trim().isEmpty) {
      _showError(
        'Please enter owner name.',
      );
      return false;
    }

    // ----------------------------------------------------------
    // PET VALIDATION
    // ----------------------------------------------------------

    for (int i = 0; i < pets.length; i++) {
      final PetData pet = pets[i];
      final int number = i + 1;

      // Pet name
      if (pet.nameController.text
          .trim()
          .isEmpty) {
        _showError(
          'Please enter Pet $number name.',
        );
        return false;
      }

      // Pet age
      if (pet.age == null) {
        _showError(
          'Please choose Pet $number age.',
        );
        return false;
      }

      // Pet breed
      if (pet.breed == null) {
        _showError(
          'Please choose Pet $number breed.',
        );
        return false;
      }

      // Pet behaviour
      if (pet.behaviour == null) {
        _showError(
          'Please choose Pet $number behaviour.',
        );
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // SAVE PROFILE + CONTINUE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE
    // ----------------------------------------------------------

    if (!_validateProfile()) {
      return;
    }

    // ----------------------------------------------------------
    // CURRENT USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError(
        'User is not logged in. Please verify your mobile number first.',
      );
      return;
    }

    // ----------------------------------------------------------
    // VERIFIED PHONE
    // ----------------------------------------------------------

    final String phone =
        user.phoneNumber?.trim() ?? '';

    if (phone.isEmpty) {
      _showError(
        'Verified mobile number was not found.',
      );
      return;
    }

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      // ========================================================
      // SAVE TO FIRESTORE
      // ========================================================

      await ProfileSetupService.saveProfile(
       ownerName: ownerController.text.trim(),
       address: addressController.text.trim(),
       phoneNumber: phone,
       pets: pets,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // SUCCESS MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              DojoBrandColors.mint,
          duration:
              const Duration(
            seconds: 1,
          ),
          content: Text(
            'Profile saved successfully with '
            '${pets.length} '
            '${pets.length == 1 ? 'pet' : 'pets'}.',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );

      // ========================================================
      // SMALL DELAY
      // ========================================================

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // GO TO MAIN NAVIGATION
      // ========================================================

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.message ??
            'Could not save profile. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'Profile Save Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showError(
        'Something went wrong. Please try again.',
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
  // ERROR MESSAGE
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
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoInputColors.lightBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return CompactPickerSheet(
          title: title,
          icon: icon,
          items: items,
          selected: selected,
          onSelected: onSelected,
        );
      },
    );
  }

  // ============================================================
  // AGE PICKER
  // ============================================================

  void _showAgePicker(
    PetData pet,
  ) {
    _openPicker(
      title: 'Choose Pet Age',
      icon:
          Icons.cake_outlined,
      items:
          ProfileSetupData.ages,
      selected:
          pet.age,
      onSelected:
          (value) {
        setState(() {
          pet.age = value;
        });

        Navigator.pop(
          context,
        );
      },
    );
  }

  // ============================================================
  // BREED PICKER
  // ============================================================

  void _showBreedPicker(
    PetData pet,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          DojoInputColors.lightBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return BreedPicker(
          breeds:
              ProfileSetupData.breeds,
          selectedBreed:
              pet.breed,
          onSelected:
              (breed) {
            setState(() {
              pet.breed = breed;
            });

            Navigator.pop(
              context,
            );
          },
        );
      },
    );
  }

  // ============================================================
  // BEHAVIOUR PICKER
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
          (value) {
        setState(() {
          pet.behaviour = value;
        });

        Navigator.pop(
          context,
        );
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
      // ========================================================
      // BACKGROUND FROM DOJO COLOR PACKAGE
      // ========================================================

      backgroundColor:
          DojoLightColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            DojoBrandColors.orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
            false,
        title:
            const Row(
          children: [
            Icon(
              Icons
                  .person_add_alt_1_rounded,
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

      body: SafeArea(
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
              // ==================================================
              // WELCOME
              // ==================================================

              const ProfileWelcomeCard(),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // OWNER INFORMATION
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
                      Icons
                          .person_outline_rounded,
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
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          DojoBrandColors
                              .orangeLight,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child:
                        Text(
                      '${pets.length}/3 Pets',
                      style:
                          const TextStyle(
                        color:
                            DojoBrandColors
                                .orange,
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight
                                .w700,
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
                (index) {
                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
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
                height: 24,
              ),

              // ==================================================
              // ADDRESS
              // ==================================================

              Text(
                'Address',
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
                height: 5,
              ),

              Text(
                'Optional',
                style:
                    TextStyle(
                  color:
                      DojoInputColors
                          .lightHint,
                  fontSize:
                      13,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              ProfileSectionCard(
                child:
                    AddressField(
                  controller:
                      addressController,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // SAVE & CONTINUE
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

              // ==================================================
              // SECURITY NOTE
              // ==================================================

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
