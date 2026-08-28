// File: lib/features/profile/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/profile_location_service.dart';
import '../widgets/address_card.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6B35);
  static const Color navy = Color(0xFF102A43);
  static const Color background = Color(0xFFF7F9FC);

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isConnecting = false;

  String _ownerId = '';
  String _ownerName = '';
  String _mobileNumber = '';
  String _ownerDob = '';
  String _ownerGender = '';
  String _memberSince = '';

  String _addressLine1 = '';
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final String uid =
          user.uid.trim();

      QuerySnapshot<Map<String, dynamic>> query =
          await FirebaseFirestore.instance
              .collection('owners')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      DocumentSnapshot<Map<String, dynamic>>? ownerDoc;

      // ----------------------------------------------------------
      // FIRST: authUid query
      // ----------------------------------------------------------

      if (query.docs.isNotEmpty) {
        ownerDoc = query.docs.first;
      } else {
        // --------------------------------------------------------
        // SECOND: owners/{uid}
        // --------------------------------------------------------

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

      // ----------------------------------------------------------
      // OWNER NOT FOUND
      // ----------------------------------------------------------

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

      // ----------------------------------------------------------
      // DATA
      // ----------------------------------------------------------

      final Map<String, dynamic> data =
          ownerDoc.data() ??
              <String, dynamic>{};

      // ----------------------------------------------------------
      // OWNER ID
      // ----------------------------------------------------------

      final String ownerId =
          _firstNonEmpty([
        data['ownerId'],
        ownerDoc.id,
      ]);

      // ----------------------------------------------------------
      // NAME
      // ----------------------------------------------------------

      final String ownerName =
          _firstNonEmpty([
        data['ownerName'],
        data['name'],
        user.displayName,
      ]);

      // ----------------------------------------------------------
      // MOBILE
      // ----------------------------------------------------------

      final String mobile =
          _firstNonEmpty([
        data['mainPhone'],
        data['phone'],
        user.phoneNumber,
      ]);

      // ----------------------------------------------------------
      // DOB
      // ----------------------------------------------------------

      final String dob =
          _firstNonEmpty([
        data['dob'],
        data['dateOfBirth'],
        data['ownerDob'],
      ]);

      // ----------------------------------------------------------
      // GENDER
      // ----------------------------------------------------------

      final String gender =
          _firstNonEmpty([
        data['gender'],
        data['ownerGender'],
      ]);

      // ----------------------------------------------------------
      // MEMBER SINCE
      // ----------------------------------------------------------

      final String memberSince =
          _formatMemberSince(
        data['createdAt'],
      );

      // ----------------------------------------------------------
      // ADDRESS LINE 1
      // ----------------------------------------------------------

      final String addressLine1 =
          _firstNonEmpty([
        data['addressLine1'],
        data['flatHouseNo'],
        data['flat'],
        data['houseNo'],
        data['houseNumber'],
        data['streetRoad'],
      ]);

      // ----------------------------------------------------------
      // AREA
      // ----------------------------------------------------------

      final String area =
          _firstNonEmpty([
        data['area'],
        data['subLocality'],
      ]);

      // ----------------------------------------------------------
      // CITY
      // ----------------------------------------------------------

      final String city =
          _firstNonEmpty([
        data['city'],
        data['locality'],
      ]);

      // ----------------------------------------------------------
      // STATE
      // ----------------------------------------------------------

      final String state =
          _firstNonEmpty([
        data['state'],
        data['administrativeArea'],
      ]);

      // ----------------------------------------------------------
      // PINCODE
      // ----------------------------------------------------------

      final String pincode =
          _firstNonEmpty([
        data['pincode'],
        data['postalCode'],
      ]);

      // ----------------------------------------------------------
      // ACTIVE
      // ----------------------------------------------------------

      final bool active =
          _boolValue(
        data['isActive'],
        fallback: true,
      );

      // ----------------------------------------------------------
      // SET STATE
      // ----------------------------------------------------------

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

        _addressLine1 =
            addressLine1;

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
  // STRING HELPERS
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
  // FIREBASE USER FALLBACK
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
      date = DateTime.tryParse(
        value,
      );
    }

    if (date == null) {
      return _stringValue(value);
    }

    return '${_monthName(date.month)} ${date.year}';
  }

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
    final bool? changed =
        await Navigator.pushNamed<bool>(
      context,
      '/change-mobile',
      arguments:
          _mobileNumber,
    );

    if (changed == true) {
      await _loadProfile();
    }
  }

  // ============================================================
  // CONNECT LOCATION
  // ============================================================

  Future<void> _connectLocation() async {
    if (_isConnecting) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final Map<String, dynamic> result =
          await ProfileLocationService
              .instance
              .connectCurrentLocation();

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // UPDATE ADDRESS ON SCREEN
      // --------------------------------------------------------

      setState(() {
        _addressLine1 =
            result['addressLine1']
                    ?.toString()
                    .trim() ??
                '';

        _area =
            result['area']
                    ?.toString()
                    .trim() ??
                '';

        _city =
            result['city']
                    ?.toString()
                    .trim() ??
                '';

        _state =
            result['state']
                    ?.toString()
                    .trim() ??
                '';

        _pincode =
            result['pincode']
                    ?.toString()
                    .trim() ??
                '';
      });

      _showMessage(
        'Current location connected successfully.',
      );
    }
    

    // ==========================================================
    // ADDRESS NOT FOUND
    // ==========================================================

    on AddressNotFoundException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not detect your address. Please try again.',
      );
    }

    // ==========================================================
    // AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Profile Location Auth Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        e.message?.trim().isNotEmpty ==
                true
            ? e.message!.trim()
            : 'Login session expired. Please login again.',
      );
    }

    // ==========================================================
    // FIREBASE / FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Profile Location Firebase Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      if (e.code ==
          'permission-denied') {
        _showMessage(
          'Location could not be saved because Firestore permission was denied.',
        );
      } else if (e.code ==
          'owner-not-found') {
        _showMessage(
          'Owner profile was not found.',
        );
      } else {
        _showMessage(
          e.message?.trim().isNotEmpty ==
                  true
              ? e.message!.trim()
              : 'Could not save your location.',
        );
      }
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Profile Location Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not connect your current location. Please try again.',
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance
          .signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context)
          .pushNamedAndRemoveUntil(
        '/mobile-login',
        (route) => false,
      );
    } catch (e) {
      debugPrint(
        'Logout Error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to logout. Please try again.',
      );
    }
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
            background,
        body: Center(
          child:
              CircularProgressIndicator(
            color: orange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            navy,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: navy,
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
          color: orange,
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
                  height: 16,
                ),

                // ==================================================
                // ADDRESS
                // ==================================================

                AddressCard(
                  flatHouseNo:
                      _addressLine1,
                  streetRoad:
                      _area,
                  landmark:
                      _buildLocationText(),
                  isConnecting:
                      _isConnecting,
                  onConnectLocation:
                      _connectLocation,
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // CHANGE MOBILE
                // ==================================================

                _ProfileActionCard(
                  icon: Icons
                      .phone_android_rounded,
                  title:
                      'Change Mobile Number',
                  subtitle:
                      'Update your registered mobile number',
                  onTap:
                      _changeMobile,
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // LOGOUT
                // ==================================================

                _ProfileActionCard(
                  icon: Icons
                      .logout_rounded,
                  title:
                      'Logout',
                  subtitle:
                      'Sign out from this account',
                  iconColor:
                      Colors.red,
                  onTap:
                      _logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION DISPLAY TEXT
  // ============================================================

  String _buildLocationText() {
    final List<String> parts =
        <String>[
      _area,
      _city,
      _state,
      _pincode,
    ]
            .where(
              (String value) =>
                  value.trim().isNotEmpty,
            )
            .map(
              (String value) =>
                  value.trim(),
            )
            .toList();

    return parts.join(', ');
  }
}

// ================================================================
// PROFILE ACTION CARD
// ================================================================

class _ProfileActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final Color color =
        iconColor ??
            const Color(
              0xFFFF6B35,
            );

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            border:
                Border.all(
              color:
                  Colors.black.withValues(
                alpha: 0.04,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.04,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF102A43,
                        ),
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF52606D,
                        ),
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.grey,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
