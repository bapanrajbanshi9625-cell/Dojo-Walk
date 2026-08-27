import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _checkLoginAndProfile();
  }

  Future<void> _checkLoginAndProfile() async {
    try {
      // =========================================================
      // 1. CHECK FIREBASE AUTH LOGIN
      // =========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      // =========================================================
      // NOT LOGGED IN
      // =========================================================

      if (user == null) {
        _goTo(const LoginScreen());
        return;
      }

      final String uid = user.uid.trim();

      if (uid.isEmpty) {
        await FirebaseAuth.instance.signOut();

        _goTo(const LoginScreen());
        return;
      }

      debugPrint(
        'Splash: Firebase user logged in: $uid',
      );

      // =========================================================
      // 2. GET PHONE ACCOUNT
      // =========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await FirebaseFirestore.instance
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      // =========================================================
      // PHONE ACCOUNT NOT FOUND
      // =========================================================

      if (!accountSnapshot.exists) {
        debugPrint(
          'Splash: phoneAccounts document not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      // =========================================================
      // 3. GET OWNER ID
      // =========================================================

      final dynamic ownerIdValue =
          accountData?['ownerId'];

      if (ownerIdValue is! String ||
          ownerIdValue.trim().isEmpty) {
        debugPrint(
          'Splash: ownerId not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final String ownerId =
          ownerIdValue.trim();

      debugPrint(
        'Splash: Owner ID = $ownerId',
      );

      // =========================================================
      // 4. GET OWNER PROFILE
      // =========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('owners')
              .doc(ownerId)
              .get();

      // =========================================================
      // OWNER PROFILE NOT FOUND
      // =========================================================

      if (!ownerSnapshot.exists) {
        debugPrint(
          'Splash: owner profile not found.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic>? ownerData =
          ownerSnapshot.data();

      // =========================================================
      // 5. CHECK ACTIVE STATUS
      // =========================================================

      final bool isActive =
          ownerData?['isActive'] != false;

      if (!isActive) {
        await FirebaseAuth.instance.signOut();

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      // =========================================================
      // 6. CHECK PROFILE COMPLETED
      // =========================================================

      final bool profileCompleted =
          ownerData?['profileCompleted'] == true;

      debugPrint(
        'Splash: profileCompleted = $profileCompleted',
      );

      // =========================================================
      // PROFILE COMPLETE → HOME
      // =========================================================

      if (profileCompleted) {
        _goTo(
          const MainNavigationScreen(),
        );

        return;
      }

      // =========================================================
      // PROFILE NOT COMPLETE → PROFILE SETUP
      // =========================================================

      _goTo(
        const ProfileSetupScreen(),
      );
    }

    // ============================================================
    // FIREBASE ERROR
    // ============================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Splash Firebase error: ${e.code}',
      );

      if (!mounted) return;

      _showFirebaseError(
        e.message ??
            'Unable to connect to Firebase.',
      );
    }

    // ============================================================
    // UNKNOWN ERROR
    // ============================================================

    catch (e) {
      debugPrint(
        'Splash unknown error: $e',
      );

      if (!mounted) return;

      _showFirebaseError(
        'Unable to load your account. Please try again.',
      );
    }
  }

  void _showFirebaseError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goTo(Widget screen) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dojo_splash.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Getting things ready...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
