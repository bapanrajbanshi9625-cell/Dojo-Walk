import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

class SplashScreen extends StatefulWidget {
  /// Phone number verified by MSG91 OTP.
  ///
  /// This is the PRIMARY identity check after OTP.
  final String? phoneNumber;

  const SplashScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _ownersCollection =
      'owners';

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _checkLoginAndProfile();
    });
  }

  // ============================================================
  // NORMALIZE PHONE
  // ============================================================

  String? _normalizePhone(
    String? phoneNumber,
  ) {
    if (phoneNumber == null) {
      return null;
    }

    String phone =
        phoneNumber
            .trim()
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

    if (phone.startsWith('91') &&
        phone.length == 12) {
      phone = phone.substring(2);
    }

    if (phone.length != 10) {
      return null;
    }

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(phone)) {
      return null;
    }

    return '+91$phone';
  }

  // ============================================================
  // CHECK LOGIN + PROFILE
  // ============================================================

  Future<void> _checkLoginAndProfile() async {
    if (_navigated) {
      return;
    }

    try {
      // ========================================================
      // 1. GET VERIFIED PHONE
      // ========================================================

      final String? phone =
          _normalizePhone(
        widget.phoneNumber,
      );

      // ========================================================
      // 2. IF OTP JUST VERIFIED
      //
      // PRIMARY CHECK IS PHONE NUMBER.
      // ========================================================

      if (phone != null) {
        debugPrint(
          'SPLASH: Checking existing account for $phone',
        );

        final Map<String, dynamic>?
            phoneAccount =
            await _findPhoneAccount(
          phone,
        );

        // ------------------------------------------------------
        // EXISTING ACCOUNT FOUND
        // ------------------------------------------------------

        if (phoneAccount != null) {
          final String ownerId =
              (phoneAccount['ownerId'] ?? '')
                  .toString()
                  .trim();

          if (ownerId.isNotEmpty) {
            debugPrint(
              'SPLASH: Existing Owner ID = $ownerId',
            );

            await _openExistingOwner(
              ownerId,
            );

            return;
          }
        }

        // ------------------------------------------------------
        // PHONE ACCOUNT NOT FOUND
        //
        // FALLBACK: SEARCH OWNER PROFILE BY PHONE
        // ------------------------------------------------------

        final Map<String, dynamic>?
            owner =
            await _findOwnerByPhone(
          phone,
        );

        if (owner != null) {
          final String ownerId =
              (owner['ownerId'] ??
                      owner['_documentId'] ??
                      '')
                  .toString()
                  .trim();

          if (ownerId.isNotEmpty) {
            debugPrint(
              'SPLASH: Existing Owner found by profile: '
              '$ownerId',
            );

            await _openExistingOwner(
              ownerId,
            );

            return;
          }
        }

        // ------------------------------------------------------
        // NO EXISTING ACCOUNT
        // ------------------------------------------------------
        //
        // IMPORTANT:
        // We DO NOT create an anonymous UID here.
        //
        // ProfileSetup will handle the new-account creation
        // flow.
        //
        // ------------------------------------------------------

        debugPrint(
          'SPLASH: No existing account found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 3. NORMAL APP START
      //
      // No phone was passed from OTP.
      // Now check existing Firebase session.
      // ========================================================

      final User? user =
          _auth.currentUser;

      if (user == null) {
        _goTo(
          const LoginScreen(),
        );
        return;
      }

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        await _auth.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      // ========================================================
      // 4. NORMAL SESSION → PHONE ACCOUNT
      // ========================================================

      final DocumentSnapshot<
              Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection(
                _phoneAccountsCollection,
              )
              .doc(uid)
              .get();

      if (!accountSnapshot.exists) {
        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic>
          accountData =
          accountSnapshot.data() ??
              <String, dynamic>{};

      final String ownerId =
          (accountData['ownerId'] ?? '')
              .toString()
              .trim();

      if (ownerId.isEmpty) {
        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      await _openExistingOwner(
        ownerId,
      );
    }

    // ==========================================================
    // FIREBASE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'SPLASH FIREBASE ERROR: ${e.code}',
      );

      if (!mounted || _navigated) {
        return;
      }

      setState(() {
        _checking = false;
      });

      _showFirebaseError(
        e.code == 'permission-denied'
            ? 'Unable to access your account. Please check Firebase permissions.'
            : e.message ??
                'Unable to connect to Firebase.',
      );
    }

    // ==========================================================
    // UNKNOWN ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'SPLASH ERROR: $e',
      );

      if (!mounted || _navigated) {
        return;
      }

      setState(() {
        _checking = false;
      });

      _showFirebaseError(
        'Unable to load your account. Please try again.',
      );
    }
  }

  // ============================================================
  // FIND PHONE ACCOUNT
  // ============================================================

  Future<Map<String, dynamic>?>
      _findPhoneAccount(
    String phone,
  ) async {
    // ----------------------------------------------------------
    // phoneNumber
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        phoneNumberQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (phoneNumberQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneNumberQuery.docs.first.data();

      data['_documentId'] =
          phoneNumberQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // phone
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        phoneQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phone',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (phoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneQuery.docs.first.data();

      data['_documentId'] =
          phoneQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // mainPhone
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        mainPhoneQuery =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'mainPhone',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (mainPhoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          mainPhoneQuery.docs.first.data();

      data['_documentId'] =
          mainPhoneQuery.docs.first.id;

      return data;
    }

    return null;
  }

  // ============================================================
  // FIND OWNER BY PHONE
  // ============================================================

  Future<Map<String, dynamic>?>
      _findOwnerByPhone(
    String phone,
  ) async {
    // ----------------------------------------------------------
    // phoneNumber
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        phoneNumberQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (phoneNumberQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneNumberQuery.docs.first.data();

      data['_documentId'] =
          phoneNumberQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // phone
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        phoneQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phone',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (phoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          phoneQuery.docs.first.data();

      data['_documentId'] =
          phoneQuery.docs.first.id;

      return data;
    }

    // ----------------------------------------------------------
    // mainPhone
    // ----------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        mainPhoneQuery =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'mainPhone',
              isEqualTo: phone,
            )
            .limit(1)
            .get();

    if (mainPhoneQuery.docs.isNotEmpty) {
      final Map<String, dynamic> data =
          mainPhoneQuery.docs.first.data();

      data['_documentId'] =
          mainPhoneQuery.docs.first.id;

      return data;
    }

    return null;
  }

  // ============================================================
  // OPEN EXISTING OWNER
  // ============================================================

  Future<void> _openExistingOwner(
    String ownerId,
  ) async {
    final DocumentSnapshot<
            Map<String, dynamic>>
        ownerSnapshot =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .doc(ownerId)
            .get();

    if (!ownerSnapshot.exists) {
      _goTo(
        const ProfileSetupScreen(),
      );

      return;
    }

    final Map<String, dynamic>
        ownerData =
        ownerSnapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // ACTIVE
    // ==========================================================

    final bool isActive =
        ownerData['isActive'] != false;

    if (!isActive) {
      await _auth.signOut();

      _goTo(
        const LoginScreen(),
      );

      return;
    }

    // ==========================================================
    // PROFILE COMPLETED
    // ==========================================================

    final bool profileCompleted =
        ownerData['profileCompleted'] == true;

    if (!profileCompleted) {
      _goTo(
        const ProfileSetupScreen(),
      );

      return;
    }

    // ==========================================================
    // MAIN APP
    // ==========================================================

    _goTo(
      const MainNavigationScreen(),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goTo(
    Widget screen,
  ) {
    if (!mounted || _navigated) {
      return;
    }

    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showFirebaseError(
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
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 5),
      ),
    );
  }

  // ============================================================
  // RETRY
  // ============================================================

  void _retry() {
    if (!mounted) {
      return;
    }

    setState(() {
      _checking = true;
    });

    _checkLoginAndProfile();
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
          const Color(0xFFF4511E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dojo_splash.png',
            fit: BoxFit.cover,
            errorBuilder:
                (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return Container(
                color:
                    const Color(0xFFF4511E),
              );
            },
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 55,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                if (_checking) ...[
                  const Text(
                    'Getting things ready...',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Unable to load your account',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  SizedBox(
                    height: 44,
                    child:
                        ElevatedButton(
                      onPressed: _retry,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors.white,
                        foregroundColor:
                            const Color(
                          0xFFF4511E,
                        ),
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
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
