import 'package:flutter/material.dart';

class OwnerHomeMarker extends StatelessWidget {
  const OwnerHomeMarker({
    super.key,
    this.size = 52,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size + 14,
      height: size + 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ====================================================
          // LOCATION SHADOW / PULSE
          // ====================================================

          Container(
            width: size + 10,
            height: size + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(
                alpha: 0.12,
              ),
            ),
          ),

          // ====================================================
          // HOME CIRCLE
          // ====================================================

          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.home_rounded,
              size: size * 0.52,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
