import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/dojo_walk_design_system.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  static const double _toolbarHeight = 56.0;

  @override
  Size get preferredSize =>
      const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    const SystemUiOverlayStyle overlayStyle =
        SystemUiOverlayStyle(
      // ======================================================
      // STATUS BAR
      // ======================================================

      statusBarColor: DojoWalkColors.primary,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,

      // ======================================================
      // NAVIGATION BAR
      // ======================================================

      systemNavigationBarColor: DojoWalkColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: AppBar(
        // ======================================================
        // APP BAR
        // ======================================================

        backgroundColor: DojoWalkColors.primary,
        foregroundColor: DojoWalkColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: DojoWalkColors.transparent,

        centerTitle: false,
        titleSpacing: 14,
        toolbarHeight: _toolbarHeight,

        systemOverlayStyle: overlayStyle,

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
                color: DojoWalkColors.white.withValues(
                  alpha: 0.18,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DojoWalkColors.white.withValues(
                    alpha: 0.35,
                  ),
                ),
              ),
              child: const Icon(
                Icons.pets,
                size: 21,
                color: DojoWalkColors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Dojo Walk',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: DojoWalkColors.white,
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
        color: DojoWalkColors.white.withValues(
          alpha: 0.17,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: DojoWalkColors.white.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: IconButton(
        tooltip: title,
        icon: Icon(
          icon,
          size: 20,
          color: DojoWalkColors.white,
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
          backgroundColor: DojoWalkColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(''),
          content: Text(
            content,
            style: const TextStyle(
              color: DojoWalkColors.textSecondary,
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
                  color: DojoWalkColors.primary,
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
