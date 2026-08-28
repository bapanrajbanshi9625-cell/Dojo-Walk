import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/active_walk.dart';

class ActiveWalkActions
    extends StatelessWidget {
  const ActiveWalkActions({
    super.key,
    required this.walk,
    required this.onChat,
    required this.onMap,
  });

  final ActiveWalk walk;
  final VoidCallback onChat;
  final VoidCallback onMap;

  static const Color green =
      Color(0xFF16A34A);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color primary =
      Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _button(
            icon: Icons.call_rounded,
            label: 'Call',
            color: green,
            onTap: () => _call(context),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _button(
            icon: Icons.chat_rounded,
            label: 'Chat',
            color: blue,
            onTap: onChat,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _button(
            icon:
                Icons.location_on_rounded,
            label: 'Map',
            color: primary,
            onTap: onMap,
          ),
        ),
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 17,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              color.withOpacity(.05),
          side: BorderSide(
            color:
                color.withOpacity(.18),
          ),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Future<void> _call(
    BuildContext context,
  ) async {
    final String phone =
        walk.walkerPhone.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Walker phone number is not available.',
          ),
        ),
      );

      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool launched =
          await launchUrl(uri);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open phone dialer.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Call error: $e',
      );
    }
  }
}
