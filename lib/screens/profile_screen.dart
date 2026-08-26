import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/profile/profile_features.dart';
import '../services/owner_id_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  // ============================================================
  // OWNER
  // ============================================================

  String ownerId = '';
  String ownerUid = '';

  String mobileNumber = '';
  String ownerName = 'Owner';
  String ownerAge = '-';
  String ownerGender = '-';
  String memberSince = '-';

  bool isActive = true;
  bool isLoading = true;
  bool isSavingPet = false;

  // ============================================================
  // PETS
  // ============================================================

  List<Map<String, dynamic>> pets = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  // ============================================================
  // LOAD OWNER PROFILE
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

      final String uid =
          user.uid.trim();

      final String? existingOwnerId =
          await OwnerIdService.instance
              .getExistingOwnerId(
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

      // ========================================================
      // IMPORTANT:
      // owners/{ownerId}
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
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

      // ========================================================
      // NAME
      // ========================================================

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

      // ========================================================
      // PHONE
      // ========================================================

      final String firestorePhone =
          data['phone']
                  ?.toString()
                  .trim() ??
              '';

      final String phone =
          firestorePhone.isNotEmpty
              ? firestorePhone
              : user.phoneNumber ?? '';

      // ========================================================
      // AGE
      // ========================================================

      final String savedAge =
          data['age']
                  ?.toString()
                  .trim() ??
              '';

      // ========================================================
      // GENDER
      // ========================================================

      final String savedGender =
          data['gender']
                  ?.toString()
                  .trim() ??
              '';

      // ========================================================
      // ACTIVE
      // ========================================================

      final bool active =
          data['isActive'] is bool
              ? data['isActive'] as bool
              : true;

      // ========================================================
      // MEMBER SINCE
      // ========================================================

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

      // ========================================================
      // PETS
      // ========================================================

      final List<Map<String, dynamic>>
          loadedPets =
          _readPets(data['pets']);

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        ownerUid = uid;
        ownerId = cleanOwnerId;

        mobileNumber =
            _formatIndianNumber(phone);

        ownerName = name;

        ownerAge =
            savedAge.isEmpty
                ? '-'
                : savedAge;

        ownerGender =
            savedGender.isEmpty
                ? '-'
                : savedGender;

        memberSince =
            joinedDate;

        isActive =
            active;

        pets =
            loadedPets;

        isLoading =
            false;
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
  // READ PETS
  // ============================================================

  List<Map<String, dynamic>> _readPets(
    dynamic value,
  ) {
    if (value is! List) {
      return [];
    }

    final List<Map<String, dynamic>>
        result = [];

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
  // FORMAT PHONE
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content:
            Text('Owner ID copied.'),
      ),
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
          currentNumber:
              mobileNumber,
          onChanged: (
            String newNumber,
          ) {
            if (!mounted) return;

            setState(() {
              mobileNumber =
                  newNumber;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // PET VALUE
  // ============================================================

  String _petValue(
    Map<String, dynamic> pet,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value =
          pet[key];

      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
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

  Future<void> _editPet(
    int index,
  ) async {
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

  Future<void> _deletePet(
    int index,
  ) async {
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
          title:
              const Text(
            'Delete Pet?',
          ),
          content:
              Text(
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
              child:
                  const Text(
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
              child:
                  const Text(
                'Delete',
                style:
                    TextStyle(
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
    final TextEditingController
        nameController =
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
          builder:
              (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom:
                      MediaQuery.of(
                        context,
                      ).viewInsets.bottom +
                          20,
                ),
                child:
                    SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
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
                                  .pets_rounded,
                              color:
                                  orange,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                Text(
                              index == null
                                  ? 'Add Pet'
                                  : 'Edit Pet',
                              style:
                                  const TextStyle(
                                fontSize:
                                    21,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    navy,
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
                              Icons
                                  .close_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // NAME
                      _EditorField(
                        controller:
                            nameController,
                        label:
                            'Pet Name',
                        hint:
                            'Enter pet name',
                        icon:
                            Icons
                                .pets_outlined,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // AGE
                      _EditorPicker(
                        label:
                            'Age',
                        value:
                            selectedAge,
                        icon:
                            Icons
                                .cake_outlined,
                        onTap:
                            () async {
                          final String?
                              result =
                              await _selectValue(
                            title:
                                'Choose Pet Age',
                            items:
                                ages,
                            selected:
                                selectedAge,
                          );

                          if (result !=
                              null) {
                            setSheetState(
                              () {
                                selectedAge =
                                    result;
                              },
                            );
                          }
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // BREED
                      _EditorPicker(
                        label:
                            'Breed',
                        value:
                            selectedBreed,
                        icon:
                            Icons
                                .pets_outlined,
                        onTap:
                            () async {
                          final String?
                              result =
                              await _selectValue(
                            title:
                                'Choose Breed',
                            items:
                                breeds,
                            selected:
                                selectedBreed,
                          );

                          if (result !=
                              null) {
                            setSheetState(
                              () {
                                selectedBreed =
                                    result;
                              },
                            );
                          }
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // BEHAVIOUR
                      _EditorPicker(
                        label:
                            'Behaviour',
                        value:
                            selectedBehaviour,
                        icon:
                            Icons
                                .favorite_border_rounded,
                        onTap:
                            () async {
                          final String?
                              result =
                              await _selectValue(
                            title:
                                'Choose Behaviour',
                            items:
                                behaviours,
                            selected:
                                selectedBehaviour,
                          );

                          if (result !=
                              null) {
                            setSheetState(
                              () {
                                selectedBehaviour =
                                    result;
                              },
                            );
                          }
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton(
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                orange,
                            foregroundColor:
                                Colors
                                    .white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          onPressed:
                              isSavingPet
                                  ? null
                                  : () async {
                                      final String
                                          name =
                                          nameController
                                              .text
                                              .trim();

                                      if (name
                                          .isEmpty) {
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

                                      if (index ==
                                          null) {
                                        if (updatedPets
                                                .length >=
                                            3) {
                                          _showMessage(
                                            'Maximum 3 pets can be added.',
                                          );
                                          return;
                                        }

                                        updatedPets
                                            .add(
                                          pet,
                                        );
                                      } else {
                                        updatedPets[
                                                index] =
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
                          child:
                              isSavingPet
                                  ? const SizedBox(
                                      width:
                                          22,
                                      height:
                                          22,
                                      child:
                                          CircularProgressIndicator(
                                        color:
                                            Colors.white,
                                        strokeWidth:
                                            2,
                                      ),
                                    )
                                  : Text(
                                      index ==
                                              null
                                          ? 'Add Pet'
                                          : 'Save Changes',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            15,
                                        fontWeight:
                                            FontWeight
                                                .w800,
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
    return await showModalBottomSheet<String>(
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
                const SizedBox(
                  height: 12,
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount:
                        items.length,
                    itemBuilder:
                        (_, index) {
                      final String item =
                          items[index];

                      final bool isSelected =
                          item ==
                              selected;

                      return ListTile(
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
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
                                  : Colors
                                      .grey,
                        ),
                        title:
                            Text(
                          item,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
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
    List<Map<String, dynamic>> updatedPets, {
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
          'pets':
              updatedPets,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) {
        return false;
      }

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
        content:
            Text(message),
        behavior:
            SnackBarBehavior.floating,
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
    return Scaffold(
      backgroundColor:
          background,

      appBar: AppBar(
        backgroundColor:
            orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon:
              const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            size: 18,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
        titleSpacing: 0,
        title:
            const Row(
          children: [
            Icon(
              Icons
                  .person_rounded,
              size: 21,
            ),
            SizedBox(
              width: 7,
            ),
            Text(
              'Profile',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child:
            isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          orange,
                      strokeWidth:
                          2.5,
                    ),
                  )
                : RefreshIndicator(
                    color:
                        orange,
                    onRefresh:
                        _loadOwnerProfile,
                    child:
                        SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        15,
                        12,
                        15,
                        30,
                      ),
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          ProfileCard(
                            ownerName:
                                ownerName,
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ==================================================
                          // OWNER INFORMATION
                          // ==================================================

                          _SectionTitle(
                            title:
                                'Owner Information',
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          _OwnerInfoCard(
                            ownerId:
                                ownerId,
                            mobileNumber:
                                mobileNumber,
                            ownerName:
                                ownerName,
                            ownerAge:
                                ownerAge,
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

                          // ==================================================
                          // PET DETAILS
                          // ==================================================

                          Row(
                            children: [
                              const Expanded(
                                child:
                                    _SectionTitle(
                                  title:
                                      'Pet Details',
                                ),
                              ),
                              if (pets
                                  .isNotEmpty)
                                Text(
                                  '${pets.length}/3 Pets',
                                  style:
                                      const TextStyle(
                                    color:
                                        orange,
                                    fontSize:
                                        12,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          if (pets
                              .isEmpty)
                            _AddPetLargeButton(
                              onPressed:
                                  _addPet,
                            )
                          else
                            ...List.generate(
                              pets.length,
                              (
                                index,
                              ) {
                                return Padding(
                                  padding:
                                      const EdgeInsets
                                          .only(
                                    bottom:
                                        12,
                                  ),
                                  child:
                                      _PetDetailsCard(
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
                              pets.length <
                                  3)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top:
                                    2,
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

// ==================================================================
// SECTION TITLE
// ==================================================================

class _SectionTitle
    extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          height: 19,
          width: 4,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF4511E,
            ),
            borderRadius:
                BorderRadius.circular(
              5,
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          title,
          style:
              const TextStyle(
            color:
                Color(0xFF263746),
            fontSize: 16,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// OWNER INFORMATION CARD
// ==================================================================

class _OwnerInfoCard
    extends StatelessWidget {
  final String ownerId;
  final String mobileNumber;
  final String ownerName;
  final String ownerAge;
  final String ownerGender;
  final String memberSince;
  final bool isActive;

  final VoidCallback onChangeMobile;
  final VoidCallback onCopyOwnerId;

  const _OwnerInfoCard({
    required this.ownerId,
    required this.mobileNumber,
    required this.ownerName,
    required this.ownerAge,
    required this.ownerGender,
    required this.memberSince,
    required this.isActive,
    required this.onChangeMobile,
    required this.onCopyOwnerId,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child:
          Column(
        children: [
          _InfoRow(
            icon:
                Icons.badge_outlined,
            label:
                'Owner ID',
            value:
                ownerId.isEmpty
                    ? '-'
                    : ownerId,
            trailing:
                ownerId.isEmpty
                    ? null
                    : IconButton(
                        icon:
                            const Icon(
                          Icons
                              .copy_rounded,
                          size: 18,
                          color:
                              Color(
                            0xFFF4511E,
                          ),
                        ),
                        onPressed:
                            onCopyOwnerId,
                      ),
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                Icons.person_outline_rounded,
            label:
                'Owner Name',
            value:
                ownerName,
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                Icons.phone_outlined,
            label:
                'Mobile Number',
            value:
                mobileNumber.isEmpty
                    ? '-'
                    : mobileNumber,
            trailing:
                IconButton(
              icon:
                  const Icon(
                Icons.edit_outlined,
                size: 19,
                color:
                    Color(
                  0xFFF4511E,
                ),
              ),
              onPressed:
                  onChangeMobile,
            ),
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                Icons.cake_outlined,
            label:
                'Age',
            value:
                ownerAge,
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                Icons.wc_outlined,
            label:
                'Gender',
            value:
                ownerGender,
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                Icons.calendar_month_outlined,
            label:
                'Member Since',
            value:
                memberSince,
          ),
          const Divider(
            height: 20,
          ),
          _InfoRow(
            icon:
                isActive
                    ? Icons
                        .check_circle_outline
                    : Icons
                        .block_outlined,
            label:
                'Account Status',
            value:
                isActive
                    ? 'Active'
                    : 'Inactive',
            valueColor:
                isActive
                    ? Colors.green
                    : Colors.red,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// INFO ROW
// ==================================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFFFF1E8,
            ),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child:
              Icon(
            icon,
            color:
                const Color(
              0xFFF4511E,
            ),
            size: 19,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize:
                      11,
                  color:
                      Colors.grey,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                style:
                    TextStyle(
                  fontSize:
                      14,
                  color:
                      valueColor ??
                          const Color(
                            0xFF263746,
                          ),
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ],
          ),
        ),
        if (trailing !=
            null)
          trailing!,
      ],
    );
  }
}

// ==================================================================
// PET DETAILS CARD
// ==================================================================

class _PetDetailsCard
    extends StatelessWidget {
  final Map<String, dynamic> pet;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetDetailsCard({
    required this.pet,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String _value(
    List<String> keys,
  ) {
    for (final String key
        in keys) {
      final dynamic value =
          pet[key];

      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }

    return '-';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final String petName =
        _value([
      'name',
      'petName',
      'pet_name',
    ]);

    final String age =
        _value([
      'age',
      'petAge',
    ]);

    final String breed =
        _value([
      'breed',
      'petBreed',
    ]);

    final String behaviour =
        _value([
      'behaviour',
      'behavior',
      'petBehaviour',
    ]);

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius:
                10,
            offset:
                const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child:
          Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFFFF1E8,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .pets_rounded,
                  color:
                      Color(
                    0xFFF4511E,
                  ),
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Pet ${index + 1}',
                      style:
                          const TextStyle(
                        fontSize:
                            11,
                        color:
                            Colors.grey,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      petName ==
                              '-'
                          ? 'Pet Name'
                          : petName,
                      style:
                          const TextStyle(
                        fontSize:
                            17,
                        color:
                            Color(
                          0xFF263746,
                        ),
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip:
                    'Edit Pet',
                onPressed:
                    onEdit,
                icon:
                    const Icon(
                  Icons
                      .edit_outlined,
                  color:
                      Color(
                    0xFFF4511E,
                  ),
                ),
              ),
              IconButton(
                tooltip:
                    'Delete Pet',
                onPressed:
                    onDelete,
                icon:
                    const Icon(
                  Icons
                      .delete_outline_rounded,
                  color:
                      Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          const Divider(
            height: 1,
          ),

          const SizedBox(
            height: 13,
          ),

          _PetRow(
            icon:
                Icons.cake_outlined,
            label:
                'Age',
            value:
                age,
          ),

          const SizedBox(
            height: 12,
          ),

          _PetRow(
            icon:
                Icons.pets_outlined,
            label:
                'Breed',
            value:
                breed,
          ),

          const SizedBox(
            height: 12,
          ),

          _PetRow(
            icon:
                Icons.favorite_border_rounded,
            label:
                'Behaviour',
            value:
                behaviour,
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// PET ROW
// ==================================================================

class _PetRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
              const Color(
            0xFFF4511E,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 75,
          child:
              Text(
            label,
            style:
                const TextStyle(
              fontSize:
                  12,
              color:
                  Colors.grey,
              fontWeight:
                  FontWeight
                      .w600,
            ),
          ),
        ),
        Expanded(
          child:
              Text(
            value,
            style:
                const TextStyle(
              fontSize:
                  13,
              color:
                  Color(
                0xFF263746,
              ),
              fontWeight:
                  FontWeight
                      .w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// ADD PET BUTTON
// ==================================================================

class _AddPetLargeButton
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddPetLargeButton({
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width:
          double.infinity,
      height: 52,
      child:
          OutlinedButton.icon(
        onPressed:
            onPressed,
        style:
            OutlinedButton
                .styleFrom(
          foregroundColor:
              const Color(
            0xFFF4511E,
          ),
          side:
              const BorderSide(
            color:
                Color(
              0xFFF4511E,
            ),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
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
                FontWeight
                    .w800,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// EDITOR FIELD
// ==================================================================

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
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      textCapitalization:
          TextCapitalization.words,
      decoration:
          InputDecoration(
        labelText:
            label,
        hintText:
            hint,
        prefixIcon:
            Icon(
          icon,
          color:
              const Color(
            0xFFF4511E,
          ),
        ),
        filled:
            true,
        fillColor:
            const Color(
          0xFFF8F8F8,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide.none,
        ),
      ),
    );
  }
}

// ==================================================================
// EDITOR PICKER
// ==================================================================

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
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      onTap:
          onTap,
      child:
          Container(
        width:
            double.infinity,
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFF8F8F8,
          ),
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        child:
            Row(
          children: [
            Icon(
              icon,
              color:
                  const Color(
                0xFFF4511E,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    label,
                    style:
                        const TextStyle(
                      fontSize:
                          11,
                      color:
                          Colors.grey,
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    value == null ||
                            value!
                                .isEmpty
                        ? 'Choose $label'
                        : value!,
                    style:
                        TextStyle(
                      fontSize:
                          14,
                      color:
                          value == null ||
                                  value!
                                      .isEmpty
                              ? Colors.grey
                              : const Color(
                                  0xFF263746,
                                ),
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
              color:
                  Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
