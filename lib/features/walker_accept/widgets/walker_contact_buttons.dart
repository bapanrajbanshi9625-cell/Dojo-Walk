import 'package:flutter/material.dart';

class WalkerContactButtons extends StatelessWidget {
  const WalkerContactButtons({
    super.key,
    required this.onCall,
    required this.onChat,
    this.callEnabled = true,
    this.chatEnabled = true,
  });

  final VoidCallback onCall;
  final VoidCallback onChat;

  final bool callEnabled;
  final bool chatEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactButton(
            icon: Icons.call_rounded,
            label: 'Call',
            onPressed: callEnabled
                ? onCall
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactButton(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            onPressed: chatEnabled
                ? onChat
                : null,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final enabled = onPressed != null;

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
                ? colors.outline
                : colors.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
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
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: enabled
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
