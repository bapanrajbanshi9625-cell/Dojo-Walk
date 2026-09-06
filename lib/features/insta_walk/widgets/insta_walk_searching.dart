// File:
// lib/features/insta_walk/widgets/insta_walk_searching.dart

import 'package:flutter/material.dart';

class InstaWalkSearching extends StatelessWidget {
  const InstaWalkSearching({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF23404D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: const Row(
        children: [
          // ======================================================
          // SEARCH ICON
          // ======================================================

          SizedBox(
            width: 34,
            height: 34,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x2E65D6C8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF8FFFEF),
                size: 19,
              ),
            ),
          ),

          SizedBox(width: 10),

          // ======================================================
          // SEARCH TEXT
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Searching for a nearby walker...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Please wait while we find an available walker.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8),

          // ======================================================
          // SEARCHING STATUS
          // ======================================================

          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x1F65D6C8),
              borderRadius: BorderRadius.all(
                Radius.circular(12),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF8FFFEF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Searching',
                    style: TextStyle(
                      color: Color(0xFF8FFFEF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
