import 'package:flutter/material.dart';

class OwnerHomeMarker extends StatelessWidget {
  const OwnerHomeMarker({
    super.key,
    this.size = 42,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              spreadRadius: 0,
              offset: Offset(0, 2),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Icon(
          Icons.home_rounded,
          size: size * 0.50,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}
