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

  String _addressLine1 = '';
  String _streetRoad = '';
  String _area = '';
  String _city = '';
  String _state = '';
  String _pincode = '';

  bool _isActive = true;

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

    try {
      final String uid = user.uid.trim();

      QuerySnapshot<Map<String, dynamic>> query =
          await FirebaseFirestore.instance
              .collection('owners')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      DocumentSnapshot<Map<String, dynamic>>?
          ownerDoc;

      // ========================================================
      // FIRST: authUid QUERY
      // ========================================================

      if (query.docs.isNotEmpty) {
        ownerDoc = query.docs.first;
      } else {
        // ======================================================
        // SECOND: owners/{uid}
        // ======================================================

        final DocumentSnapshot<
            Map<String, dynamic>> directDoc =
            await FirebaseFirestore.instance
                .collection('owners')
                .doc(uid)
                .get();

        if (directDoc.exists) {
          ownerDoc = directDoc;
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
          _ownerName =
              _firebaseName(user);

          _mobileNumber =
              _firebasePhone(user);

          _isLoading = false;
        });

        return;
      }

      // ========================================================
      // DATA
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
      ]);

      // ========================================================
      // NAME
      // ========================================================

      final String ownerName =
          _firstNonEmpty([
        data['ownerName'],
        data['name'],
        user.displayName,
      ]);

      // ========================================================
      // MOBILE
      // ========================================================

      final String mobile =
          _firstNonEmpty([
        data['mainPhone'],
        data['phone'],
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
      // FLAT / HOUSE
      // ========================================================

      final String addressLine1 =
          _firstNonEmpty([
        data['addressLine1'],
        data['flatHouseNo'],
        data['flat'],
        data['houseNo'],
        data['houseNumber'],
      ]);

      // ========================================================
      // STREET / ROAD
      // ========================================================

      final String streetRoad =
          _firstNonEmpty([
        data['streetRoad'],
        data['street'],
        data['road'],
        data['addressLine2'],
      ]);

      // ========================================================
      // AREA
      // ========================================================

      final String area =
          _firstNonEmpty([
        data['area'],
        data['subLocality'],
      ]);

      // ========================================================
      // CITY
      // ========================================================

      final String city =
          _firstNonEmpty([
        data['city'],
        data['locality'],
      ]);

      // ========================================================
      // STATE
      // ========================================================

      final String state =
          _firstNonEmpty([
        data['state'],
        data['administrativeArea'],
      ]);

      // ========================================================
      // PINCODE
      // ========================================================

      final String pincode =
          _firstNonEmpty([
        data['pincode'],
        data['postalCode'],
      ]);

      // ========================================================
      // ACTIVE
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

        _addressLine1 = addressLine1;
        _streetRoad = streetRoad;
        _area = area;
        _city = city;
        _state = state;
        _pincode = pincode;

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
  // STRING HELPERS
  // ============================================================

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

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
  // FIREBASE USER FALLBACK
  // ============================================================

  String _firebaseName(User? user) {
    final String name =
        user?.displayName?.trim() ?? '';

    return name.isNotEmpty
        ? name
        : 'Owner';
  }

  String _firebasePhone(User? user) {
    final String phone =
        user?.phoneNumber?.trim() ?? '';

    return phone.isNotEmpty
        ? phone
        : 'Not available';
  }

  // ============================================================
  // BOOL HELPER
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
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return _stringValue(value);
    }

    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
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
      backgroundColor: AppColors.white,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return ChangeMobileFlow(
          currentNumber: number,
          onChanged: (_) {},
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
            color: AppColors.orange,
          ),
        ),
      );
    }

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
            color: AppColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
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
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  height: 16,
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
