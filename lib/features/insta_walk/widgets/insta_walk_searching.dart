// File location:
// lib/features/insta_walk/widgets/insta_walk_searching.dart

import 'package:flutter/material.dart';

class InstaWalkSearching extends StatelessWidget {
  final Widget map;

  const InstaWalkSearching({
    super.key,
    required this.map,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==========================================================
        // SEARCH HEADER
        // ==========================================================

        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF65D6C8).withValues(
                  alpha: 0.18,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFF8FFFEF),
                size: 19,
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Finding an available walker',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // ======================================================
            // SEARCHING STATUS
            // ======================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF65D6C8).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF8FFFEF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Searching',
                    style: TextStyle(
                      color: Color(0xFF8FFFEF),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ==========================================================
        // MAP + RADAR
        // ==========================================================

        map,

        const SizedBox(height: 12),

        // ==========================================================
        // LOCATION PRIVACY INFO
        // ==========================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF8FFFEF),
                size: 17,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your location is used only as a search snapshot.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
