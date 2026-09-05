import 'package:flutter/material.dart';

class WalkerLocationMarker extends StatelessWidget {
  const WalkerLocationMarker({
    super.key,
    this.imageUrl,
    this.size = 44,
    this.isLive = true,
  });

  final String? imageUrl;
  final double size;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
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
                width: 2.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 7,
                  spreadRadius: 0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _fallback(context);
                      },
                    )
                  : _fallback(context),
            ),
          ),

          // ====================================================
          // LIVE DOT
          // ====================================================

          if (isLive)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.8,
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
        Icons.person_rounded,
        size: size * 0.50,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }
}
