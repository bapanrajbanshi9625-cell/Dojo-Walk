import 'package:flutter/material.dart';

class WalkerLocationMarker extends StatelessWidget {
  const WalkerLocationMarker({
    super.key,
    this.imageUrl,
    this.size = 58,
    this.isLive = true,
  });

  final String? imageUrl;
  final double size;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageUrl != null &&
        imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ====================================================
          // LIVE PULSE
          // ====================================================

          if (isLive)
            Container(
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.14),
              ),
            ),

          // ====================================================
          // WALKER PHOTO
          // ====================================================

          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _fallback(context),
                    )
                  : _fallback(context),
            ),
          ),

          // ====================================================
          // LIVE DOT
          // ====================================================

          if (isLive)
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: size * 0.52,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }
}
