import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import '../features/profile_setup/screens/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? phoneNumber;

  const SplashScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _ownersCollection =
      'owners';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndProfile();
    });
  }

  // ============================================================
  // CHECK LOGIN + PROFILE
  // ============================================================

  Future<void> _checkLoginAndProfile() async {
    if (_navigated) {
      return;
    }

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      // ========================================================
      // 1. RESTORE SAVED DOJO ACCOUNT
      // ========================================================

      final bool otpVerified =
          prefs.getBool('tempOtpVerified') ?? false;

      final bool existingAccount =
          prefs.getBool('tempExistingAccount') ?? false;

      final String savedOwnerId =
          (prefs.getString('tempOwnerId') ?? '')
              .trim();

      final String savedAccountUid =
          (prefs.getString('tempAccountUid') ?? '')
              .trim();

      final bool savedProfileCompleted =
          prefs.getBool('tempProfileCompleted') ?? false;

      debugPrint(
        'SPLASH: otpVerified = $otpVerified',
      );

      debugPrint(
        'SPLASH: existingAccount = $existingAccount',
      );

      debugPrint(
        'SPLASH: savedOwnerId = $savedOwnerId',
      );

      debugPrint(
        'SPLASH: savedAccountUid = $savedAccountUid',
      );

      debugPrint(
        'SPLASH: savedProfileCompleted = '
        '$savedProfileCompleted',
      );

      // ========================================================
      // 2. EXISTING ACCOUNT
      // ========================================================
      //
      // IMPORTANT:
      // Existing account is identified by ownerId.
      // We do NOT require current Firebase anonymous UID
      // to match the old account UID.
      //

      if (otpVerified &&
          existingAccount &&
          savedOwnerId.isNotEmpty) {
        debugPrint(
          'SPLASH: Existing Dojo owner restored.',
        );

        // ------------------------------------------------------
        // Read the actual owner document.
        // This is the final source of truth.
        // ------------------------------------------------------

        debugPrint(
          'SPLASH: Reading owners/$savedOwnerId',
        );

        final DocumentSnapshot<Map<String, dynamic>>
            ownerSnapshot =
            await _firestore
                .collection(_ownersCollection)
                .doc(savedOwnerId)
                .get();

        if (!ownerSnapshot.exists) {
          debugPrint(
            'SPLASH: Existing owner document not found.',
          );

          _goTo(
            const ProfileSetupScreen(),
          );

          return;
        }

        final Map<String, dynamic> ownerData =
            ownerSnapshot.data() ??
                <String, dynamic>{};

        // ------------------------------------------------------
        // ACTIVE
        // ------------------------------------------------------

        final bool isActive =
            ownerData['isActive'] != false;

        if (!isActive) {
          debugPrint(
            'SPLASH: Owner account inactive.',
          );

          await prefs.clear();

          await _auth.signOut();

          _goTo(
            const LoginScreen(),
          );

          return;
        }

        // ------------------------------------------------------
        // PROFILE COMPLETED
        // ------------------------------------------------------

        final bool profileCompleted =
            ownerData['profileCompleted'] == true;

        debugPrint(
          'SPLASH: Firestore profileCompleted = '
          '$profileCompleted',
        );

        // ------------------------------------------------------
        // EXISTING + COMPLETE
        // ------------------------------------------------------

        if (profileCompleted) {
          debugPrint(
            'SPLASH: Existing profile complete.',
          );

          await prefs.setBool(
            'tempProfileCompleted',
            true,
          );

          _goTo(
            const MainNavigationScreen(),
          );

          return;
        }

        // ------------------------------------------------------
        // EXISTING + INCOMPLETE
        // ------------------------------------------------------

        debugPrint(
          'SPLASH: Existing profile incomplete.',
        );

        await prefs.setBool(
          'tempProfileCompleted',
          false,
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 3. NEW ACCOUNT
      // ========================================================

      if (otpVerified && !existingAccount) {
        debugPrint(
          'SPLASH: New owner account.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 4. LEGACY SESSION RECOVERY
      // ========================================================
      //
      // If SharedPreferences doesn't contain the new login
      // state, fall back to Firebase Auth for older sessions.
      //

      final User? user =
          _auth.currentUser;

      debugPrint(
        'SPLASH: Firebase UID = ${user?.uid}',
      );

      if (user == null) {
        debugPrint(
          'SPLASH: No saved login session.',
        );

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
      // 5. LEGACY PHONE ACCOUNT
      // ========================================================

      debugPrint(
        'SPLASH: Reading phoneAccounts/$uid',
      );

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection(_phoneAccountsCollection)
              .doc(uid)
              .get();

      if (!accountSnapshot.exists) {
        debugPrint(
          'SPLASH: Legacy phone account not found.',
        );

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      final Map<String, dynamic> accountData =
          accountSnapshot.data() ??
              <String, dynamic>{};

      final String ownerId =
          (accountData['ownerId'] ?? '')
              .toString()
              .trim();

      if (ownerId.isEmpty) {
        debugPrint(
          'SPLASH: Legacy ownerId missing.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 6. LEGACY OWNER
      // ========================================================

      debugPrint(
        'SPLASH: Reading owners/$ownerId',
      );

      final DocumentSnapshot<Map<String, dynamic>>
          ownerSnapshot =
          await _firestore
              .collection(_ownersCollection)
              .doc(ownerId)
              .get();

      if (!ownerSnapshot.exists) {
        debugPrint(
          'SPLASH: Legacy owner not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic> ownerData =
          ownerSnapshot.data() ??
              <String, dynamic>{};

      final bool isActive =
          ownerData['isActive'] != false;

      if (!isActive) {
        await _auth.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      final bool profileCompleted =
          ownerData['profileCompleted'] == true;

      debugPrint(
        'SPLASH: Legacy profileCompleted = '
        '$profileCompleted',
      );

      if (profileCompleted) {
        _goTo(
          const MainNavigationScreen(),
        );

        return;
      }

      _goTo(
        const ProfileSetupScreen(),
      );
    }

    // ==========================================================
    // FIREBASE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'SPLASH FIREBASE ERROR: '
        '${e.code} - ${e.message}',
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
            errorBuilder: (
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
                          ElevatedButton.styleFrom(
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
                              BorderRadius.circular(
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
