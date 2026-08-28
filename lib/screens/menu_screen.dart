import 'package:flutter/material.dart';

import '../core/theme/colors/dojo_brand_colors.dart';
import '../core/theme/colors/dojo_light_colors.dart';
import '../core/theme/colors/dojo_card_colors.dart';
import '../widgets/menu_card.dart';
import '../widgets/section_title.dart';

import 'custom_app_bar.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'address_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // ============================================================
  // OPEN PAGE
  // ============================================================

  void _openPage(
    BuildContext context,
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              color: DojoBrandColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: DojoBrandColors.slate,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoBrandColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoLightColors.background,

      // ========================================================
      // DOJO WALK APP BAR
      // ========================================================

      appBar: const CustomAppBar(),

      // ========================================================
      // BODY
      // ========================================================

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          15,
          16,
          15,
          30,
        ),
        children: [
          // ======================================================
          // ACCOUNT
          // ======================================================

          const SectionTitle(
            title: 'ACCOUNT',
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle:
                'Manage your profile information',
            onTap: () {
              _openPage(
                context,
                const ProfileScreen(),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.location_on_outlined,
            title: 'Address',
            subtitle:
                'Update your home or walking address',
            onTap: () {
              _openPage(
                context,
                const AddressScreen(),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle:
                'Manage your notification preferences',
            onTap: () {
              _openPage(
                context,
                const NotificationsScreen(),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // APP
          // ======================================================

          const SectionTitle(
            title: 'APP',
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle:
                'Manage your Dojo Walk app settings',
            onTap: () {
              _openPage(
                context,
                const SettingsScreen(),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // SUPPORT
          // ======================================================

          const SectionTitle(
            title: 'SUPPORT',
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle:
                'Get help with your Dojo Walk account',
            onTap: () {
              _openPage(
                context,
                const HelpSupportScreen(),
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          MenuCard(
            icon: Icons.info_outline,
            title: 'About Dojo Walk',
            subtitle:
                'App information and version',
            onTap: () {
              _openPage(
                context,
                const AboutScreen(),
              );
            },
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // LOGOUT
          // ======================================================

          MenuCard(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            iconColor: DojoCardColors.error,
            titleColor: DojoCardColors.error,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),

          const SizedBox(
            height: 30,
          ),

          // ======================================================
          // FOOTER
          // ======================================================

          const Center(
            child: Text(
              'Dojo Walk',
              style: TextStyle(
                color: DojoBrandColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: DojoBrandColors.slate,
                fontSize: 11,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
