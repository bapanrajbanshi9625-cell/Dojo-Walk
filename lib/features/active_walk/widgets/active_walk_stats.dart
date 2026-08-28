import 'package:flutter/material.dart';

import '../models/active_walk.dart';

class ActiveWalkStats extends StatelessWidget {
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
    return Row(
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
            'Status',
            _statusText(),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _stat(
            Icons.location_on_rounded,
            'Location',
            walk.hasWalkerLocation
                ? 'Live'
                : 'Waiting',
          ),
        ),
      ],
    );
  }

  String _statusText() {
    switch (walk.normalizedStatus) {
      case 'on_the_way':
      case 'on_that_way':
        return 'On Way';

      case 'reached':
        return 'Reached';

      case 'walking':
      case 'in_progress':
        return 'Walking';

      case 'completed':
      case 'ended':
        return 'Ended';

      default:
        return 'Active';
    }
  }

  Widget _stat(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
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
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              color: slate,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
