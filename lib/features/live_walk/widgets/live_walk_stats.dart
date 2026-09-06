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

  static const Color orange = Color(0xFFFF6B35);
  static const Color navy = Color(0xFF263746);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                label: 'MINUTES',
                value: _minutesValue(duration),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'KM',
                value: _distanceValue(distance),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                label: 'STEPS',
                value: _formatNumber(steps),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _peePoopCard(),
      ],
    );
  }

  String _minutesValue(String value) {
    final parts = value.split(':');

    if (parts.length == 2) {
      return parts[0];
    }

    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      return (hours * 60 + minutes).toString();
    }

    return value;
  }

  String _distanceValue(String value) {
    return value
        .replaceAll(' km', '')
        .replaceAll(' KM', '')
        .trim();
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }

  Widget _statCard({
    required String label,
    required String value,
  }) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _peePoopCard() {
    return Container(
      width: double.infinity,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8EDF2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'PEE / POOP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$peeCount / $poopCount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}
