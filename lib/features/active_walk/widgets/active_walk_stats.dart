import 'package:flutter/material.dart';

import '../models/active_walk.dart';

class ActiveWalkStats
    extends StatelessWidget {
  const ActiveWalkStats({
    super.key,
    required this.walk,
    required this.duration,
  });

  final ActiveWalk walk;
  final String duration;

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color slate =
      Color(0xFF475569);

  static const Color lightBg =
      Color(0xFFF7F8F9);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _stat(
                Icons.timer_outlined,
                'Duration',
                duration,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _stat(
                Icons.directions_walk_rounded,
                'Steps',
                '${walk.steps}',
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _stat(
                Icons.route_rounded,
                'Distance',
                walk.distance,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _smallStat(
                Icons.water_drop_rounded,
                'Pee',
                walk.peeCount,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStat(
                Icons.eco_rounded,
                'Poop',
                walk.poopCount,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stat(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: primary,
            size: 18,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              color: slate,
              fontSize: 8,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat(
    IconData icon,
    String title,
    int value,
  ) {
    return Container(
      height: 42,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              color: slate,
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
