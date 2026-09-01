import 'package:flutter/material.dart';

class WalkerEtaDistance extends StatelessWidget {
  const WalkerEtaDistance({
    super.key,
    required this.distanceMeters,
    required this.etaMinutes,
  });

  final double distanceMeters;
  final int etaMinutes;

  String get distanceText {
    if (distanceMeters <= 0) {
      return '--';
    }

    if (distanceMeters >= 1000) {
      final km = distanceMeters / 1000;

      return km >= 10
          ? '${km.toStringAsFixed(0)} km'
          : '${km.toStringAsFixed(1)} km';
    }

    return '${distanceMeters.round()} m';
  }

  String get etaText {
    if (etaMinutes <= 0) {
      return 'Arriving';
    }

    if (etaMinutes == 1) {
      return '1 min';
    }

    return '$etaMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.near_me_rounded,
            value: distanceText,
            label: 'Distance',
          ),
        ),

        Container(
          width: 1,
          height: 42,
          color: colors.outlineVariant,
        ),

        Expanded(
          child: _Metric(
            icon: Icons.access_time_rounded,
            value: etaText,
            label: 'Estimated arrival',
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 21,
          color: colors.primary,
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          child: Text(
            value,
            key: ValueKey(value),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
