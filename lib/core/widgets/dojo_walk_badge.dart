import 'package:flutter/material.dart';

import '../theme/dojo_walk_colors.dart';
import '../theme/dojo_walk_radius.dart';

enum DojoWalkBadgeType {
  brand,
  info,
  success,
  warning,
  error,
  neutral,
}

class DojoWalkBadge extends StatelessWidget {
  final String text;
  final DojoWalkBadgeType type;
  final IconData? icon;
  final bool compact;

  const DojoWalkBadge({
    super.key,
    required this.text,
    this.type = DojoWalkBadgeType.neutral,
    this.icon,
    this.compact = false,
  });

  Color get _foregroundColor {
    switch (type) {
      case DojoWalkBadgeType.brand:
        return DojoWalkColors.primary;

      case DojoWalkBadgeType.info:
        return DojoWalkColors.blue;

      case DojoWalkBadgeType.success:
        return DojoWalkColors.green;

      case DojoWalkBadgeType.warning:
        return DojoWalkColors.amber;

      case DojoWalkBadgeType.error:
        return DojoWalkColors.red;

      case DojoWalkBadgeType.neutral:
        return DojoWalkColors.textSecondary;
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case DojoWalkBadgeType.brand:
        return DojoWalkColors.primaryLight;

      case DojoWalkBadgeType.info:
        return DojoWalkColors.blueLight;

      case DojoWalkBadgeType.success:
        return DojoWalkColors.greenLight;

      case DojoWalkBadgeType.warning:
        return DojoWalkColors.amberLight;

      case DojoWalkBadgeType.error:
        return DojoWalkColors.redLight;

      case DojoWalkBadgeType.neutral:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = compact ? 8.0 : 10.0;
    final vertical = compact ? 4.0 : 6.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(
          DojoWalkRadius.pill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 13 : 15,
              color: _foregroundColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: _foregroundColor,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
