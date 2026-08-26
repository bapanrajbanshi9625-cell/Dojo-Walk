// File location:
// lib/screens/profile_screen.dart

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
  String address = '';

  bool isActive = true;
  bool profileCompleted = false;
  bool isLoading = true;

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
          FirebaseAuth
              .instance
              .currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final String uid =
          user.uid.trim();

      ownerUid = uid;

      // ========================================================
      // GET OWNER ID
      // ========================================================

      final String? existingOwnerId =
          await OwnerIdService
              .instance
              .getExistingOwnerId(
        uid: uid,
      );

      if (existingOwnerId == null ||
          existingOwnerId
              .trim()
              .isEmpty) {
        debugPrint(
          'Owner ID not found.',
        );

        if (!mounted) return;

        setState(() {
          ownerId = '';
          isLoading = false;
        });

        return;
      }

      final String cleanOwnerId =
          existingOwnerId.trim();

      // ========================================================
      // LOAD owners/OWN26GM0001
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore
              .instance
              .collection(
                'owners',
              )
              .doc(
                cleanOwnerId,
              )
              .get();

      if (!snapshot.exists) {
        debugPrint(
          'Owner document does not exist: '
          'owners/$cleanOwnerId',
        );

        if (!mounted) return;

        setState(() {
          ownerId =
              cleanOwnerId;
          isLoading = false;
        });

        return;
      }

      final Map<String, dynamic>?
          data =
          snapshot.data();

      if (data == null) {
        if (!mounted) return;

        setState(() {
          ownerId =
              cleanOwnerId;
          isLoading = false;
        });

        return;
      }

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

      final String savedPhone =
          data['phone']
                  ?.toString()
                  .trim() ??
              '';

      final String phone =
          savedPhone.isNotEmpty
              ? savedPhone
              : user.phoneNumber
                      ?.trim() ??
                  '';

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
      // ADDRESS
      // ========================================================

      final String savedAddress =
          data['address']
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
      // PROFILE COMPLETED
      // ========================================================

      final bool completed =
          data['profileCompleted']
                  is bool
              ? data['profileCompleted']
                  as bool
              : false;

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
          _readPets(
        data['pets'],
      );

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '================================',
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
        'Address: $savedAddress',
      );

      debugPrint(
        'Profile Completed: $completed',
      );

      debugPrint(
        'Pets: ${loadedPets.length}',
      );

      debugPrint(
        '================================',
      );

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        ownerUid =
            uid;

        ownerId =
            cleanOwnerId;

        mobileNumber =
            _formatIndianNumber(
          phone,
        );

        ownerName =
            name;

        ownerAge =
            savedAge.isNotEmpty
                ? savedAge
                : '-';

        ownerGender =
            savedGender.isNotEmpty
                ? savedGender
                : '-';

        memberSince =
            joinedDate;

        address =
            savedAddress;

        isActive =
            active;

        profileCompleted =
            completed;

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

    for (final dynamic item
        in value) {
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

    return months[month];
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
      backgroundColor:
          Colors.white,
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
        backgroundColor:
            Color(0xFF303030),
        content: Text(
          'Owner ID copied.',
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
          onPressed:
              () {
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
                          // OWNER INFORMATION
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

                          if (pets.isEmpty)
                            const _EmptyPetCard()
                          else
                            ...List.generate(
                              pets.length,
                              (
                                int index,
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
  final String memberSince;
  final bool isActive;

  final VoidCallback
      onChangeMobile;

  final VoidCallback
      onCopyOwnerId;

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
            icon: isActive
                ? Icons
                    .check_circle_outline
                : Icons
                    .block_outlined,
            label:
                'Account Status',
            value: isActive
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
                      BorderRadius
                          .circular(
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
// EMPTY PET
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
            color:
                Colors.grey,
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
