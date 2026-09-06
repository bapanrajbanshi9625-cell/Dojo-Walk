import 'package:flutter/material.dart';

import '../theme/dojo_walk_colors.dart';
import '../theme/dojo_walk_radius.dart';
import '../theme/dojo_walk_shadows.dart';

class DojoWalkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showShadow;

  const DojoWalkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width,
    this.onTap,
    this.showBorder = true,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: DojoWalkColors.surface,
        borderRadius: BorderRadius.circular(
          DojoWalkRadius.lg,
        ),
        border: showBorder
            ? Border.all(
                color: DojoWalkColors.border,
              )
            : null,
        boxShadow:
            showShadow ? DojoWalkShadows.soft : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          DojoWalkRadius.lg,
        ),
        child: card,
      ),
    );
  }
}
