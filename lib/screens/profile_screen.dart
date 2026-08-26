import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/profile/profile_features.dart';
import '../features/profile_setup/services/profile_setup_service.dart';

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
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  // ============================================================
  // OWNER DATA
  // ============================================================

  String ownerId = '';
  String ownerUid = '';

  String mobileNumber = '';
  String ownerName = 'Owner';

  String ownerAge = '-';
  String ownerGender = '-';
  String memberSince = '-';
  String address = '-';

  String profilePhotoUrl = '';

  bool isActive = true;
  bool profileCompleted = false;
  bool isLoading = true;

  // ============================================================
  // PET DATA
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
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // ========================================================
      // FIREBASE USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // AUTH UID
      // ========================================================

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // GET OWNER ID
      // ========================================================

      String? currentOwnerId =
          await ProfileSetupService
              .getCurrentOwnerId();

      // ========================================================
      // FALLBACK:
      // FIND OWNER USING authUid
      // ========================================================

      if (currentOwnerId == null ||
          currentOwnerId.trim().isEmpty) {
        final QuerySnapshot<
                Map<String, dynamic>>
            query =
            await FirebaseFirestore
                .instance
                .collection('owners')
                .where(
                  'authUid',
                  isEqualTo: uid,
                )
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          currentOwnerId =
              query.docs.first.id;
        }
      }

      // ========================================================
      // OWNER ID NOT FOUND
      // ========================================================

      if (currentOwnerId == null ||
          currentOwnerId.trim().isEmpty) {
        debugPrint(
          'Owner profile not found for UID: $uid',
        );

        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          ownerId = '';
          isLoading = false;
        });

        return;
      }

      currentOwnerId =
          currentOwnerId.trim();

      // ========================================================
      // GET OWNER DOCUMENT
      //
      // owners/OWN26GM0001
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore
              .instance
              .collection('owners')
              .doc(currentOwnerId)
              .get();

      // ========================================================
      // DOCUMENT NOT FOUND
      // ========================================================

      if (!snapshot.exists) {
        debugPrint(
          'Owner document does not exist: $currentOwnerId',
        );

        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          ownerId = currentOwnerId!;
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // DOCUMENT DATA
      // ========================================================

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        if (!mounted) return;

        setState(() {
          ownerUid = uid;
          ownerId = currentOwnerId!;
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // OWNER ID
      // ========================================================

      final String documentOwnerId =
          snapshot.id.trim();

      final String fieldOwnerId =
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      final String cleanOwnerId =
          documentOwnerId.isNotEmpty
              ? documentOwnerId
              : fieldOwnerId;

      // ========================================================
      // OWNER NAME
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

      final String age =
          savedAge.isNotEmpty
              ? savedAge
              : '-';

      // ========================================================
      // GENDER
      // ========================================================

      final String savedGender =
          data['gender']
                  ?.toString()
                  .trim() ??
              '';

      final String gender =
          savedGender.isNotEmpty
              ? savedGender
              : '-';

      // ========================================================
      // ADDRESS
      // ========================================================

      final String savedAddress =
          data['address']
                  ?.toString()
                  .trim() ??
              '';

      final String cleanAddress =
          savedAddress.isNotEmpty
              ? savedAddress
              : '-';

      // ========================================================
      // ACTIVE
      //
      // Firestore standard:
      //
      // isActive: true
      // ========================================================

      bool active = true;

      final dynamic activeValue =
          data['isActive'];

      if (activeValue is bool) {
        active = activeValue;
      }

      // ========================================================
      // PROFILE COMPLETED
      // ========================================================

      bool completed = false;

      final dynamic completedValue =
          data['profileCompleted'];

      if (completedValue is bool) {
        completed = completedValue;
      }

      // ========================================================
      // PROFILE PHOTO
      // ========================================================

      final dynamic photoValue =
          data['profilePhotoUrl'] ??
              data['profilePhoto'];

      final String photo =
          photoValue
                  ?.toString()
                  .trim() ??
              '';

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
      } else {
        final dynamic memberSinceValue =
            data['memberSince'];

        if (memberSinceValue != null) {
          final String value =
              memberSinceValue
                  .toString()
                  .trim();

          if (value.isNotEmpty) {
            joinedDate = value;
          }
        }
      }

      // ========================================================
      // PETS
      // ========================================================

      final List<Map<String, dynamic>>
          loadedPets =
          _readPets(
        data['pets'],
      );

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        'OWNER PROFILE',
      );

      debugPrint(
        'Collection: owners',
      );

      debugPrint(
        'Document: $cleanOwnerId',
      );

      debugPrint(
        'Auth UID: $uid',
      );

      debugPrint(
        'Name: $name',
      );

      debugPrint(
        'Phone: $phone',
      );

      debugPrint(
        'Profile Completed: $completed',
      );

      debugPrint(
        'Pets: ${loadedPets.length}',
      );

      debugPrint(
        '========================================',
      );

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        ownerUid = uid;

        ownerId = cleanOwnerId;

        mobileNumber =
            _formatIndianNumber(
          phone,
        );

        ownerName = name;

        ownerAge = age;

        ownerGender = gender;

        address = cleanAddress;

        memberSince = joinedDate;

        isActive = active;

        profileCompleted = completed;

        profilePhotoUrl = photo;

        pets = loadedPets;

        isLoading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore Profile Error: ${e.code}',
      );

      debugPrint(
        e.message ?? '',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            e.message ??
                'Could not load profile.',
          ),
        ),
      );
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
  //
  // Expected Firestore:
  //
  // pets: [
  //   {
  //     name: "Bruno",
  //     age: "2 Years",
  //     breed: "Labrador",
  //     behaviour: "Friendly"
  //   }
  // ]
  //
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
          Map<String, dynamic>.from(
            item,
          ),
        );
      }
    }

    return result;
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

      if (value != null) {
        final String text =
            value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return '-';
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

  String _monthName(
    int month,
  ) {
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
    if (ownerId.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: ownerId,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Owner ID copied.',
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE MOBILE
  // ============================================================

  void _openChangeMobile() {
    if (mobileNumber.isEmpty ||
        mobileNumber == '-') {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Current mobile number is not available.',
          ),
        ),
      );

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
          onChanged:
              (String newNumber) {
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            orange,
        foregroundColor:
            Colors.white,
        elevation: 0,
        toolbarHeight: 52,
        leading:
            IconButton(
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
              Icons.person_rounded,
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

      // ========================================================
      // BODY
      // ========================================================

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
                      // ==================================================
                      // PROFILE CARD
                      // ==================================================

                      ProfileCard(
                        ownerName:
                            ownerName,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // OWNER INFORMATION TITLE
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            height: 19,
                            width: 4,
                            decoration:
                                BoxDecoration(
                              color:
                                  orange,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                5,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            'Owner Information',
                            style:
                                TextStyle(
                              color:
                                  navy,
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==================================================
                      // OWNER INFORMATION
                      // ==================================================

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
                        address:
                            address,
                        memberSince:
                            memberSince,
                        isActive:
                            isActive,
                        profileCompleted:
                            profileCompleted,
                        onChangeMobile:
                            _openChangeMobile,
                        onCopyOwnerId:
                            _copyOwnerId,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ==================================================
                      // PET TITLE
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            height: 19,
                            width: 4,
                            decoration:
                                BoxDecoration(
                              color:
                                  orange,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                5,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            'Pet Details',
                            style:
                                TextStyle(
                              color:
                                  navy,
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                          const Spacer(),
                          if (pets.isNotEmpty)
                            Text(
                              '${pets.length} '
                              '${pets.length == 1 ? 'Pet' : 'Pets'}',
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

                      // ==================================================
                      // PETS
                      // ==================================================

                      if (pets.isEmpty)
                        const _EmptyPetCard()
                      else
                        ...List.generate(
                          pets.length,
                          (index) {
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
                              ),
                            );
                          },
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
// OWNER INFORMATION CARD
// ==================================================================

class _OwnerInfoCard
    extends StatelessWidget {
  final String ownerId;
  final String mobileNumber;
  final String ownerName;
  final String ownerAge;
  final String ownerGender;
  final String address;
  final String memberSince;

  final bool isActive;
  final bool profileCompleted;

  final VoidCallback onChangeMobile;
  final VoidCallback onCopyOwnerId;

  const _OwnerInfoCard({
    required this.ownerId,
    required this.mobileNumber,
    required this.ownerName,
    required this.ownerAge,
    required this.ownerGender,
    required this.address,
    required this.memberSince,
    required this.isActive,
    required this.profileCompleted,
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
                          size:
                              18,
                          color:
                              orange,
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
                color: orange,
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
                Icons.location_on_outlined,
            label:
                'Address',
            value:
                address,
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
                profileCompleted
                    ? Icons
                        .verified_outlined
                    : Icons
                        .warning_amber_rounded,
            label:
                'Profile',
            value:
                profileCompleted
                    ? 'Completed'
                    : 'Incomplete',
            valueColor:
                profileCompleted
                    ? Colors.green
                    : Colors.orange,
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
          width:
              36,
          height:
              36,
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
            size:
                19,
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
                maxLines: 3,
                overflow:
                    TextOverflow
                        .ellipsis,
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

        if (trailing != null)
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

  const _PetDetailsCard({
    required this.pet,
    required this.index,
  });

  String _value(
    List<String> keys,
  ) {
    for (final String key
        in keys) {
      final dynamic value =
          pet[key];

      if (value != null) {
        final String text =
            value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
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
                width:
                    46,
                height:
                    46,
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
                  Icons.pets_rounded,
                  color:
                      Color(
                    0xFFF4511E,
                  ),
                  size:
                      25,
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
                      petName == '-'
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
// EMPTY PET CARD
// ==================================================================

class _EmptyPetCard
    extends StatelessWidget {
  const _EmptyPetCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          const Column(
        children: [
          Icon(
            Icons.pets_outlined,
            size: 34,
            color: Colors.grey,
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'No pet details available.',
            style:
                TextStyle(
              color:
                  Colors.grey,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
