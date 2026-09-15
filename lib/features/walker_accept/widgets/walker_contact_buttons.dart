import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class WalkerContactButtons extends StatelessWidget {
  const WalkerContactButtons({
    super.key,
    required this.onChat,
    this.phoneNumber,
    this.callEnabled = true,
    this.chatEnabled = true,
  });

  final VoidCallback onChat;
  final String? phoneNumber;

  final bool callEnabled;
  final bool chatEnabled;

  Future<void> _makeCall() async {
    final String? phone = phoneNumber?.trim();

    if (phone == null || phone.isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.call_rounded,
            label: 'Call',
            onPressed: callEnabled && phoneNumber != null
                ? _makeCall
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            onPressed: chatEnabled ? onChat : null,
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: enabled
                ? DojoWalkColors.border
                : DojoWalkColors.divider,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? DojoWalkColors.primary
                  : DojoWalkColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DojoWalkColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
