// File:
// lib/screens/splash_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _SplashScreenState extends State<SplashScreen> {
  bool _checking = true;
  bool _navigated = false;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static const String _phoneAccountsCollection =
      'phoneAccounts';

  static const String _ownersCollection =
      'owners';

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
  // NORMALIZE PHONE
  // ==========================================================

  String? _normalizePhone(
    String? phoneNumber,
  ) {
    if (phoneNumber == null) {
      return null;
    }

    String clean =
        phoneNumber
            .trim()
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

    if (clean.startsWith('91') &&
        clean.length == 12) {
      clean = clean.substring(2);
    }

    if (clean.length != 10) {
      return null;
    }

    if (!RegExp(
      r'^[6-9][0-9]{9}$',
    ).hasMatch(clean)) {
      return null;
    }

    return clean;
  }

  // ==========================================================
  // GET SAVED PHONE
  // ==========================================================
  //
  // Login screen should save the verified phone number locally.
  //
  // This allows Splash to recover an existing Owner even when
  // Firebase Anonymous UID changes after reinstall.
  //
  // ==========================================================

  Future<String?> _getSavedPhone() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String? phone =
          prefs.getString(
        'owner_phone_number',
      );

      return _normalizePhone(phone);
    } catch (e) {
      debugPrint(
        'Splash: Unable to read saved phone: $e',
      );

      return null;
    }
  }

  // ==========================================================
  // SAVE CURRENT PHONE
  // ==========================================================

  Future<void> _savePhone(
    String phone,
  ) async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'owner_phone_number',
        phone,
      );
    } catch (e) {
      debugPrint(
        'Splash: Unable to save phone: $e',
      );
    }
  }

  // ==========================================================
  // FIND OWNER BY PHONE
  // ==========================================================

  Future<String?> _findOwnerIdByPhone(
    String phone,
  ) async {
    final String cleanPhone =
        _normalizePhone(phone) ?? '';

    if (cleanPhone.isEmpty) {
      return null;
    }

    final String fullPhone =
        '+91$cleanPhone';

    // ========================================================
    // 1. phoneAccounts.phone = 10 DIGITS
    // ========================================================

    QuerySnapshot<Map<String, dynamic>>
        query =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phone',
              isEqualTo: cleanPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final String? ownerId =
          _extractOwnerId(
        query.docs.first.data(),
      );

      if (ownerId != null) {
        return ownerId;
      }
    }

    // ========================================================
    // 2. phoneAccounts.phone = +91XXXXXXXXXX
    // ========================================================

    query =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phone',
              isEqualTo: fullPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final String? ownerId =
          _extractOwnerId(
        query.docs.first.data(),
      );

      if (ownerId != null) {
        return ownerId;
      }
    }

    // ========================================================
    // 3. phoneAccounts.phoneNumber
    // ========================================================

    query =
        await _firestore
            .collection(
              _phoneAccountsCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: fullPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final String? ownerId =
          _extractOwnerId(
        query.docs.first.data(),
      );

      if (ownerId != null) {
        return ownerId;
      }
    }

    // ========================================================
    // 4. owners.phone
    // ========================================================

    query =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phone',
              isEqualTo: cleanPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return _extractOwnerId(
        query.docs.first.data(),
        fallbackId: query.docs.first.id,
      );
    }

    // ========================================================
    // 5. owners.phone = +91XXXXXXXXXX
    // ========================================================

    query =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phone',
              isEqualTo: fullPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return _extractOwnerId(
        query.docs.first.data(),
        fallbackId: query.docs.first.id,
      );
    }

    // ========================================================
    // 6. owners.phoneNumber
    // ========================================================

    query =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .where(
              'phoneNumber',
              isEqualTo: fullPhone,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return _extractOwnerId(
        query.docs.first.data(),
        fallbackId: query.docs.first.id,
      );
    }

    return null;
  }

  // ==========================================================
  // EXTRACT OWNER ID
  // ==========================================================

  String? _extractOwnerId(
    Map<String, dynamic> data, {
    String? fallbackId,
  }) {
    final dynamic value =
        data['ownerId'];

    if (value != null) {
      final String ownerId =
          value.toString().trim();

      if (ownerId.isNotEmpty) {
        return ownerId;
      }
    }

    if (fallbackId != null &&
        fallbackId.trim().isNotEmpty) {
      return fallbackId.trim();
    }

    return null;
  }

  // ==========================================================
  // RECONNECT CURRENT UID
  // ==========================================================

  Future<void> _reconnectCurrentUid({
    required String uid,
    required String ownerId,
    required String phone,
  }) async {
    final String cleanPhone =
        _normalizePhone(phone) ?? '';

    if (cleanPhone.isEmpty) {
      return;
    }

    final String fullPhone =
        '+91$cleanPhone';

    // ========================================================
    // phoneAccounts/{CURRENT UID}
    // ========================================================

    await _firestore
        .collection(
          _phoneAccountsCollection,
        )
        .doc(uid)
        .set(
      <String, dynamic>{
        'uid': uid,
        'authUid': uid,
        'ownerId': ownerId,
        'phone': cleanPhone,
        'phoneNumber': fullPhone,
        'mainPhone': fullPhone,
        'role': 'owner',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // owners/{OWNER ID}
    // ========================================================
    //
    // IMPORTANT:
    // profileCompleted is NOT touched here.
    //
    // Existing profile remains exactly as it is.
    //
    // ========================================================

    await _firestore
        .collection(
          _ownersCollection,
        )
        .doc(ownerId)
        .set(
      <String, dynamic>{
        'ownerId': ownerId,
        'uid': uid,
        'authUid': uid,
        'phone': cleanPhone,
        'phoneNumber': fullPhone,
        'mainPhone': fullPhone,
        'role': 'owner',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    debugPrint(
      'Splash: Existing Owner reconnected.',
    );

    debugPrint(
      'Splash: Owner ID = $ownerId',
    );

    debugPrint(
      'Splash: New Firebase UID = $uid',
    );
  }

  // ==========================================================
  // LOAD OWNER AND NAVIGATE
  // ==========================================================

  Future<void> _loadOwnerAndNavigate({
    required String ownerId,
    required String uid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>>
        ownerSnapshot =
        await _firestore
            .collection(
              _ownersCollection,
            )
            .doc(ownerId)
            .get();

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

    // ========================================================
    // ACTIVE
    // ========================================================

    final bool isActive =
        ownerData['isActive'] != false;

    debugPrint(
      'Splash: isActive = $isActive',
    );

    if (!isActive) {
      debugPrint(
        'Splash: Owner account inactive.',
      );

      await _auth.signOut();

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

    debugPrint(
      'Splash: profileCompleted = '
      '$profileCompleted',
    );

    // ========================================================
    // COMPLETE
    // ========================================================

    if (profileCompleted) {
      debugPrint(
        'Splash: Existing completed Owner.',
      );

      _goTo(
        const MainNavigationScreen(),
      );

      return;
    }

    // ========================================================
    // INCOMPLETE
    // ========================================================

    debugPrint(
      'Splash: Owner profile incomplete.',
    );

    _goTo(
      const ProfileSetupScreen(),
    );
  }

  // ==========================================================
  // CHECK LOGIN + PROFILE
  // ==========================================================

  Future<void> _checkLoginAndProfile() async {
    if (_navigated) {
      return;
    }

    try {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'SPLASH: CHECKING LOGIN',
      );

      debugPrint(
        '==========================================',
      );

      // ========================================================
      // 1. FIREBASE USER
      // ========================================================

      final User? user =
          _auth.currentUser;

      if (user == null) {
        debugPrint(
          'Splash: No Firebase session.',
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

      debugPrint(
        'Splash: Firebase UID = $uid',
      );

      // ========================================================
      // 2. FIRST CHECK UID ACCOUNT
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          accountSnapshot =
          await _firestore
              .collection(
                _phoneAccountsCollection,
              )
              .doc(uid)
              .get();

      if (accountSnapshot.exists) {
        final Map<String, dynamic> accountData =
            accountSnapshot.data() ??
                <String, dynamic>{};

        final dynamic ownerIdValue =
            accountData['ownerId'];

        if (ownerIdValue != null) {
          final String ownerId =
              ownerIdValue.toString().trim();

          if (ownerId.isNotEmpty) {
            debugPrint(
              'Splash: Owner ID found by UID = $ownerId',
            );

            await _loadOwnerAndNavigate(
              ownerId: ownerId,
              uid: uid,
            );

            return;
          }
        }
      }

      // ========================================================
      // 3. UID NOT FOUND
      //
      // This can happen after reinstall because Anonymous UID
      // can be different.
      //
      // ========================================================

      debugPrint(
        'Splash: Current UID has no phone account.',
      );

      // ========================================================
      // 4. RECOVER PHONE
      // ========================================================

      final String? savedPhone =
          await _getSavedPhone();

      if (savedPhone == null) {
        debugPrint(
          'Splash: No saved phone available.',
        );

        _goTo(
          const LoginScreen(),
        );

        return;
      }

      debugPrint(
        'Splash: Saved phone found.',
      );

      // ========================================================
      // 5. FIND OLD OWNER BY PHONE
      // ========================================================

      final String? existingOwnerId =
          await _findOwnerIdByPhone(
        savedPhone,
      );

      if (existingOwnerId == null ||
          existingOwnerId.trim().isEmpty) {
        debugPrint(
          'Splash: No existing Owner found for phone.',
        );

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final String ownerId =
          existingOwnerId.trim();

      debugPrint(
        'Splash: Existing Owner found by phone.',
      );

      debugPrint(
        'Splash: Owner ID = $ownerId',
      );

      // ========================================================
      // 6. RECONNECT NEW UID TO OLD OWNER
      // ========================================================

      await _reconnectCurrentUid(
        uid: uid,
        ownerId: ownerId,
        phone: savedPhone,
      );

      // ========================================================
      // 7. LOAD OLD OWNER PROFILE
      // ========================================================

      await _loadOwnerAndNavigate(
        ownerId: ownerId,
        uid: uid,
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
        '$e',
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
  // ERROR
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
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 5),
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
