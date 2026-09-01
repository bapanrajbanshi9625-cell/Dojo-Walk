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
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
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
      final User? user =
          FirebaseAuth.instance.currentUser;

      // ========================================================
      // NO FIREBASE SESSION
      // ========================================================

      if (user == null) {
        _goTo(
          const LoginScreen(),
        );
        return;
      }

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        await FirebaseAuth.instance.signOut();

        _goTo(
          const LoginScreen(),
        );
        return;
      }

      // ========================================================
      // PHONE ACCOUNT
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await FirebaseFirestore.instance
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      if (!accountSnapshot.exists) {
        // Authenticated user but account not created.
        _goTo(
          const ProfileSetupScreen(),
        );
        return;
      }

      final Map<String, dynamic> accountData =
          accountSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // OWNER ID
      // ========================================================

      final dynamic ownerIdValue =
          accountData['ownerId'];

      if (ownerIdValue == null) {
        _goTo(
          const ProfileSetupScreen(),
        );
        return;
      }

      final String ownerId =
          ownerIdValue.toString().trim();

      if (ownerId.isEmpty) {
        _goTo(
          const ProfileSetupScreen(),
        );
        return;
      }

      // ========================================================
      // OWNER PROFILE
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(ownerId)
              .get();

      if (!ownerSnapshot.exists) {
        _goTo(
          const ProfileSetupScreen(),
        );
        return;
      }

      final Map<String, dynamic> ownerData =
          ownerSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // ACTIVE
      // ========================================================

      final bool isActive =
          ownerData['isActive'] != false;

      if (!isActive) {
        await FirebaseAuth.instance.signOut();

        _goTo(
          const LoginScreen(),
        );
        return;
      }

      // ========================================================
      // PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          ownerData['profileCompleted'] == true;

      if (!profileCompleted) {
        _goTo(
          const ProfileSetupScreen(),
        );
        return;
      }

      // ========================================================
      // MAIN APP
      // ========================================================

      _goTo(
        const MainNavigationScreen(),
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
