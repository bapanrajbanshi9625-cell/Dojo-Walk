import 'package:flutter/material.dart';

import '../theme/dojo_walk_colors.dart';
import '../theme/dojo_walk_radius.dart';

class DojoWalkIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const DojoWalkIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: backgroundColor ?? DojoWalkColors.surface,
        borderRadius: BorderRadius.circular(
          DojoWalkRadius.md,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            DojoWalkRadius.md,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? DojoWalkColors.textPrimary,
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}
