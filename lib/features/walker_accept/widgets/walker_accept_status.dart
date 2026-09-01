import 'package:flutter/material.dart';

class WalkerAcceptStatus extends StatelessWidget {
  const WalkerAcceptStatus({
    super.key,
    required this.status,
    this.distanceMeters = 0,
  });

  final String status;
  final double distanceMeters;

  bool get isReached =>
      status.trim().toLowerCase() == 'reached';

  bool get isArriving {
    if (isReached) {
      return false;
    }

    return distanceMeters > 0 &&
        distanceMeters <= 300;
  }

  String get title {
    if (isReached) {
      return 'Walker has arrived';
    }

    if (isArriving) {
      return 'Walker is arriving';
    }

    return 'Walker is on the way';
  }

  String get subtitle {
    if (isReached) {
      return 'Your walker has reached your saved location.';
    }

    if (isArriving) {
      return 'Your walker is very close to you.';
    }

    return 'Live location and arrival time are updating.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(
              alpha: 0.10,
            ),
          ),
          child: Icon(
            isReached
                ? Icons.check_circle_rounded
                : isArriving
                    ? Icons.near_me_rounded
                    : Icons.directions_walk_rounded,
            color: colors.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
