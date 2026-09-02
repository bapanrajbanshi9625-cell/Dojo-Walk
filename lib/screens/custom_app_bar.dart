import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  static const double _toolbarHeight = 56.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // ======================================================
        // STATUS BAR
        // ======================================================

        statusBarColor: AppColors.orange,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,

        // ======================================================
        // NAVIGATION BAR
        // ======================================================

        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: AppBar(
        // ======================================================
        // APP BAR
        // ======================================================

        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        centerTitle: false,
        titleSpacing: 14,
        toolbarHeight: _toolbarHeight,

        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.orange,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),

        // ======================================================
        // LEFT — DOJO WALK
        // ======================================================

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.pets,
                size: 21,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Dojo Walk',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ],
        ),

        // ======================================================
        // RIGHT ACTIONS
        // ======================================================

        actions: [
          _appBarButton(
            context,
            Icons.notifications_outlined,
            'Notifications',
          ),
          _appBarButton(
            context,
            Icons.support_agent,
            'Help & Support',
          ),
          const SizedBox(width: 7),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR BUTTON
  // ============================================================

  Widget _appBarButton(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.17),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.30),
        ),
      ),
      child: IconButton(
        tooltip: title,
        icon: const Icon(
          Icons.notifications_outlined,
          size: 20,
          color: AppColors.white,
        ),
        onPressed: () {
          _showDialog(
            context,
            title,
            '$title button pressed.',
          );
        },
      ),
    );
  }

  // ============================================================
  // DIALOG
  // ============================================================

  void _showDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '',
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: AppColors.slate,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
