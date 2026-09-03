import 'package:flutter/material.dart';

class LiveWalkStats extends StatelessWidget {
  const LiveWalkStats({
    super.key,
    required this.duration,
    required this.steps,
    required this.distance,
    required this.peeCount,
    required this.poopCount,
  });

  final String duration;
  final int steps;
  final String distance;
  final int peeCount;
  final int poopCount;

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color slate =
      Color(0xFF475569);

  static const Color lightBg =
      Color(0xFFF7F8F9);

  static const Color border =
      Color(0xFFE5E7EB);

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
                '$steps',
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _stat(
                Icons.route_rounded,
                'Distance',
                distance,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _toilet(
                Icons.water_drop_rounded,
                'Pee',
                peeCount,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _toilet(
                Icons.eco_rounded,
                'Poop',
                poopCount,
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
        vertical: 8,
        horizontal: 4,
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

  Widget _toilet(
    IconData icon,
    String title,
    int value,
  ) {
    return Container(
      height: 40,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 17,
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
