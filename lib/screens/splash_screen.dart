import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // ========================================================
      // 1. FIREBASE AUTH USER
      // ========================================================

      final User? user = _auth.currentUser;

      debugPrint(
        'SPLASH: Firebase UID = ${user?.uid}',
      );

      // ========================================================
      // 2. NOT SIGNED INTO FIREBASE
      // ========================================================

      if (user == null) {
        debugPrint(
          'SPLASH: No Firebase Auth user found.',
        );

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        await _auth.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      // ========================================================
      // 3. PHONE ACCOUNT
      //
      // IMPORTANT:
      // Document ID = Firebase Auth UID
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

      // ========================================================
      // 4. ACCOUNT DOES NOT EXIST
      // ========================================================

      if (!accountSnapshot.exists) {
        debugPrint(
          'SPLASH: phoneAccounts/$uid not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic> accountData =
          accountSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // 5. OWNER ID
      // ========================================================

      final String ownerId =
          (accountData['ownerId'] ?? '')
              .toString()
              .trim();

      debugPrint(
        'SPLASH: Owner ID = $ownerId',
      );

      if (ownerId.isEmpty) {
        debugPrint(
          'SPLASH: ownerId missing.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 6. OWNER DOCUMENT
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

      // ========================================================
      // 7. OWNER DOES NOT EXIST
      // ========================================================

      if (!ownerSnapshot.exists) {
        debugPrint(
          'SPLASH: owners/$ownerId not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic> ownerData =
          ownerSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // 8. ACTIVE CHECK
      // ========================================================

      final bool isActive =
          ownerData['isActive'] != false;

      if (!isActive) {
        debugPrint(
          'SPLASH: Owner account is inactive.',
        );

        await _auth.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      // ========================================================
      // 9. PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          ownerData['profileCompleted'] == true;

      debugPrint(
        'SPLASH: profileCompleted = $profileCompleted',
      );

      if (!profileCompleted) {
        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 10. MAIN APP
      // ========================================================

      debugPrint(
        'SPLASH: Owner account ready.',
      );

      _goTo(
        const MainNavigationScreen(),
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
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
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
