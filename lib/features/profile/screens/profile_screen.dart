// File: lib/features/profile/screens/profile_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/address_card.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);
  static const Color background = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String ownerName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Owner';

    final String phoneNumber =
        user?.phoneNumber?.trim().isNotEmpty == true
            ? user!.phoneNumber!.trim()
            : 'Not available';

    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PROFILE CARD
              // ==================================================

              ProfileCard(
                ownerName: ownerName,
              ),

              const SizedBox(height: 16),

              // ==================================================
              // OWNER INFORMATION
              // ==================================================

              OwnerInfoCard(
                ownerName: ownerName,
                phoneNumber: phoneNumber,
              ),

              const SizedBox(height: 16),

              // ==================================================
              // ADDRESS
              // ==================================================

              const AddressCard(),

              const SizedBox(height: 24),

              // ==================================================
              // CHANGE MOBILE
              // ==================================================

              _ProfileActionCard(
                icon: Icons.phone_android_rounded,
                title: 'Change Mobile Number',
                subtitle: 'Update your registered mobile number',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/change-mobile',
                  );
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // LOGOUT
              // ==================================================

              _ProfileActionCard(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from this account',
                iconColor: Colors.red,
                onTap: () async {
                  await _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/mobile-login',
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to logout. Please try again.',
          ),
        ),
      );
    }
  }
}

// ================================================================
// PROFILE ACTION CARD
// ================================================================

class _ProfileActionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color color =
        iconColor ?? ProfileScreen.orange;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // TEXT
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ProfileScreen.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ARROW
              // ==================================================

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
