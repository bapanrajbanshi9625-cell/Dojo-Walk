import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  static const orange = Color(0xFFF4511E);
  static const navy = Color(0xFF263746);
  static const slate = Color(0xFF475569);

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // =========================================
      // APP BAR + STATUS BAR
      // =========================================

      backgroundColor: orange,
      foregroundColor: Colors.white,

      // Android status bar will use the same orange.
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: orange,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),

      elevation: 0,
      centerTitle: false,
      titleSpacing: 14,

      // =========================================
      // LEFT — DOJO WALK
      // =========================================

      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: const Icon(
              Icons.pets,
              size: 21,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 10),

          const Text(
            'Dojo Walk',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),

      // =========================================
      // RIGHT — NOTIFICATIONS + HELP
      // =========================================

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
    );
  }

  // =========================================
  // APP BAR BUTTON
  // =========================================

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
        color: Colors.white.withValues(
          alpha: 0.17,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: IconButton(
        tooltip: title,
        icon: Icon(
          icon,
          size: 20,
          color: Colors.white,
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

  // =========================================
  // DIALOG
  // =========================================

  void _showDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFFF7F8FA),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),

          content: Text(
            content,
            style: const TextStyle(
              color: slate,
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
                  color: orange,
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
