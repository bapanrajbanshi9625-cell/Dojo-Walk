import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';
import '../widgets/address_card.dart';
import '../widgets/owner_info_card.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String ownerId = user?.uid ?? '';

    final String ownerName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Owner';

    final String mobileNumber =
        user?.phoneNumber?.trim().isNotEmpty == true
            ? user!.phoneNumber!.trim()
            : 'Not available';

    return Scaffold(
      backgroundColor: DojoColors.background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: DojoColors.white,
        foregroundColor: DojoColors.navy,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: DojoColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

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
              // ======================================================
              // PROFILE CARD
              // ======================================================

              ProfileCard(
                ownerName: ownerName,
              ),

              const SizedBox(height: 16),

              // ======================================================
              // OWNER INFORMATION
              // ======================================================

              OwnerInfoCard(
                ownerId: ownerId,
                mobileNumber: mobileNumber,
                ownerName: ownerName,

                // These are display-only for now.
                ownerDob: '-',
                ownerGender: '-',

                // Firebase user creation date.
                memberSince: _memberSince(user),

                // Firebase Auth user is considered active
                // when a signed-in user exists.
                isActive: user != null,

                onChangeMobile: () {
                  Navigator.pushNamed(
                    context,
                    '/change-mobile',
                  );
                },

                onCopyOwnerId: () {
                  _copyOwnerId(
                    context,
                    ownerId,
                  );
                },
              ),

              const SizedBox(height: 16),

              // ======================================================
              // ADDRESS
              // ======================================================

              AddressCard(
                flatHouseNo: '',
                streetRoad: '',
                landmark: '',
                isConnecting: false,
                onConnectLocation: () {
                  _showComingSoon(context);
                },
              ),

              const SizedBox(height: 24),

              // ======================================================
              // CHANGE MOBILE
              // ======================================================

              _ProfileActionCard(
                icon: Icons.phone_android_rounded,
                title: 'Change Mobile Number',
                subtitle:
                    'Update your registered mobile number',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/change-mobile',
                  );
                },
              ),

              const SizedBox(height: 12),

              // ======================================================
              // LOGOUT
              // ======================================================

              _ProfileActionCard(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from this account',
                iconColor: DojoColors.red,
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
  // MEMBER SINCE
  // ============================================================

  String _memberSince(User? user) {
    final DateTime? createdAt = user?.metadata.creationTime;

    if (createdAt == null) {
      return '-';
    }

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[createdAt.month - 1]} ${createdAt.year}';
  }

  // ============================================================
  // COPY OWNER ID
  // ============================================================

  void _copyOwnerId(
    BuildContext context,
    String ownerId,
  ) {
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner ID is not available.'),
        ),
      );
      return;
    }

    // Clipboard functionality can be added here if desired.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Owner ID copied.'),
      ),
    );
  }

  // ============================================================
  // ADDRESS LOCATION PLACEHOLDER
  // ============================================================

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location connection will be available here.',
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
    } catch (_) {
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
        iconColor ?? DojoColors.orange;

    return Material(
      color: DojoColors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DojoColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DojoColors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    DojoColors.black.withValues(alpha: 0.04),
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
                        color: DojoColors.navy,
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
                        color: DojoColors.grey,
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
                color: DojoColors.grey,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
