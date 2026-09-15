import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/dojo_walk_design_system.dart';
import '../../contact/screens/chat_screen.dart';

class WalkerContactButtons extends StatelessWidget {
  const WalkerContactButtons({
    super.key,
    required this.onChat,
    required this.walkId,
    required this.requestId,
    required this.sessionId,
    required this.ownerUid,
    required this.walkerUid,
    this.ownerPhone = '',
    this.walkerPhone = '',
    this.phoneNumber,
    this.callEnabled = true,
    this.chatEnabled = true,
  });

  final VoidCallback onChat;

  final String walkId;
  final String requestId;
  final String sessionId;

  final String ownerUid;
  final String walkerUid;

  final String ownerPhone;
  final String walkerPhone;

  final String? phoneNumber;

  final bool callEnabled;
  final bool chatEnabled;

  Future<void> _makeCall() async {
    final String? phone =
        phoneNumber?.trim();

    if (phone == null ||
        phone.isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      await launchUrl(uri);
    } catch (error) {
      debugPrint(
        'WalkerContactButtons call error: $error',
      );
    }
  }

  void _openChat(BuildContext context) {
    if (!chatEnabled) {
      return;
    }

    // Existing chat callback remains available.
    onChat();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          walkId: walkId,
          requestId: requestId,
          sessionId: sessionId,
          ownerUid: ownerUid,
          walkerUid: walkerUid,
          ownerPhone: ownerPhone,
          walkerPhone: walkerPhone,
          title: 'Chat',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayNumber =
        phoneNumber?.trim().isNotEmpty == true
            ? phoneNumber!.trim()
            : 'Call';

    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.call_rounded,
            label: displayNumber,
            onPressed:
                callEnabled &&
                        phoneNumber
                                ?.trim()
                                .isNotEmpty ==
                            true
                    ? _makeCall
                    : null,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _ContactButton(
            icon:
                Icons.chat_bubble_rounded,
            label: 'Chat',
            onPressed: chatEnabled
                ? () => _openChat(context)
                : null,
          ),
        ),
      ],
    );
  }
}

class _ContactButton
    extends StatelessWidget {
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
    final bool enabled =
        onPressed != null;

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: enabled
                ? DojoWalkColors.border
                : DojoWalkColors.divider,
          ),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? DojoWalkColors.primary
                  : DojoWalkColors
                      .textTertiary,
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w700,
                  color: enabled
                      ? DojoWalkColors
                          .textPrimary
                      : DojoWalkColors
                          .textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
