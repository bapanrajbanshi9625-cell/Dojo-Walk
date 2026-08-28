// File:
// lib/screens/splash_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginAndProfile();
    });
  }

  // ==========================================================
  // CHECK LOGIN + PROFILE
  // ==========================================================

  Future<void> _checkLoginAndProfile() async {
    if (_navigated) {
      return;
    }

    try {
      debugPrint('==========================================');
      debugPrint('SPLASH: CHECKING LOGIN');
      debugPrint('==========================================');

      // ========================================================
      // 1. FIREBASE AUTH USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint(
          'Splash: No Firebase user found.',
        );

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        debugPrint(
          'Splash: Firebase UID is empty.',
        );

        await FirebaseAuth.instance.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      debugPrint(
        'Splash: Firebase UID = $uid',
      );

      // ========================================================
      // 2. PHONE ACCOUNT
      //
      // phoneAccounts/{firebaseUid}
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await FirebaseFirestore.instance
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      // ========================================================
      // PHONE ACCOUNT DOES NOT EXIST
      // ========================================================

      if (!accountSnapshot.exists) {
        debugPrint(
          'Splash: phoneAccounts/$uid does not exist.',
        );

        // ------------------------------------------------------
        // IMPORTANT:
        // Do NOT sign out here.
        //
        // User is authenticated, but account/profile setup
        // has not been completed yet.
        // ------------------------------------------------------

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic> accountData =
          accountSnapshot.data() ??
              <String, dynamic>{};

      debugPrint(
        'Splash: phoneAccounts data loaded.',
      );

      // ========================================================
      // 3. OWNER ID
      // ========================================================

      final dynamic ownerIdValue =
          accountData['ownerId'];

      if (ownerIdValue == null) {
        debugPrint(
          'Splash: ownerId is missing.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final String ownerId =
          ownerIdValue.toString().trim();

      if (ownerId.isEmpty) {
        debugPrint(
          'Splash: ownerId is empty.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      debugPrint(
        'Splash: ownerId = $ownerId',
      );

      // ========================================================
      // 4. OWNER PROFILE
      //
      // owners/{ownerId}
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(ownerId)
              .get();

      // ========================================================
      // OWNER PROFILE DOES NOT EXIST
      // ========================================================

      if (!ownerSnapshot.exists) {
        debugPrint(
          'Splash: owners/$ownerId does not exist.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic> ownerData =
          ownerSnapshot.data() ??
              <String, dynamic>{};

      debugPrint(
        'Splash: owner profile loaded.',
      );

      // ========================================================
      // 5. CHECK ACCOUNT ACTIVE
      // ========================================================

      final dynamic activeValue =
          ownerData['isActive'];

      final bool isActive =
          activeValue == null ||
          activeValue == true;

      debugPrint(
        'Splash: isActive = $isActive',
      );

      if (!isActive) {
        debugPrint(
          'Splash: owner account is inactive.',
        );

        await FirebaseAuth.instance.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      // ========================================================
      // 6. CHECK PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          ownerData['profileCompleted'] == true;

      debugPrint(
        'Splash: profileCompleted = '
        '$profileCompleted',
      );

      // ========================================================
      // 7. PROFILE COMPLETE
      // ========================================================

      if (profileCompleted) {
        debugPrint(
          'Splash: Profile complete.',
        );

        debugPrint(
          'Splash: Opening MainNavigationScreen.',
        );

        _goTo(
          const MainNavigationScreen(),
        );

        return;
      }

      // ========================================================
      // 8. PROFILE INCOMPLETE
      // ========================================================

      debugPrint(
        'Splash: Profile incomplete.',
      );

      _goTo(
        const ProfileSetupScreen(),
      );
    }

    // ==========================================================
    // FIREBASE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'SPLASH FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrint(
        '==========================================',
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
        '==========================================',
      );

      debugPrint(
        'SPLASH UNKNOWN ERROR',
      );

      debugPrint(
        '$e',
      );

      debugPrint(
        '==========================================',
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

  // ==========================================================
  // NAVIGATION
  // ==========================================================

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

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void _showFirebaseError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 5,
          ),
        ),
      );
  }

  // ==========================================================
  // RETRY
  // ==========================================================

  void _retry() {
    if (!mounted) {
      return;
    }

    setState(() {
      _checking = true;
    });

    _checkLoginAndProfile();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
          // ====================================================
          // SPLASH IMAGE
          // ====================================================

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

          // ====================================================
          // LOADING / ERROR
          // ====================================================

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
                    child: ElevatedButton(
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
