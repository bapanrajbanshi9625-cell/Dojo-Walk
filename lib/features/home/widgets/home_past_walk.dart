import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomePastWalk extends StatelessWidget {
  const HomePastWalk({
    super.key,
    required this.walks,
    required this.onDetails,
  });

  // =====================================================
  // FIRESTORE DATA
  // =====================================================

  final List<Map<String, dynamic>> walks;

  final void Function(
    String title,
    String content,
  ) onDetails;

  @override
  Widget build(BuildContext context) {
    // ===================================================
    // EMPTY STATE
    // ===================================================

    if (walks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'No past walks found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.slate,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // ===================================================
    // PAST WALKS
    // ===================================================

    return Column(
      children: [
        for (int i = 0; i < walks.length; i++) ...[
          _walkCard(
            walk: walks[i],
          ),
          if (i != walks.length - 1)
            const SizedBox(height: 7),
        ],
      ],
    );
  }

  // =====================================================
  // WALK CARD
  // =====================================================

  Widget _walkCard({
    required Map<String, dynamic> walk,
  }) {
    // ===================================================
    // SAFE FIRESTORE VALUES
    // ===================================================

    final String id = _stringValue(
      walk['walkId'] ??
          walk['id'] ??
          walk['walkID'],
      fallback: 'Walk',
    );

    final String time = _stringValue(
      walk['timeFormatted'] ??
          walk['time'] ??
          walk['startTime'],
      fallback: '--',
    );

    final String date = _stringValue(
      walk['date'] ??
          walk['walkDate'] ??
          walk['createdDate'],
      fallback: '--',
    );

    final String distance = _formatDistance(
      walk['distance'] ??
          walk['distanceKm'] ??
          walk['totalDistance'],
    );

    final String duration = _formatDuration(
      walk['durationMinutes'] ??
          walk['duration'] ??
          walk['totalDuration'],
    );

    final String route = _stringValue(
      walk['route'] ??
          walk['routeName'] ??
          walk['location'],
      fallback: 'Route information unavailable',
    );

    final String status = _stringValue(
      walk['status'],
      fallback: 'Completed',
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          onDetails(
            'Walk Details',
            'Walk ID: $id\n'
            'Time: $time\n'
            'Date: $date\n'
            'Duration: $duration\n'
            'Distance: $distance\n'
            'Route: $route\n'
            'Status: $status',
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(
                  alpha: 0.045,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // =========================================
              // WALK ICON
              // =========================================

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              // =========================================
              // WALK INFORMATION
              // =========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$id • $time',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Flexible(
                          child: _infoText(
                            Icons.route_outlined,
                            distance,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: _infoText(
                            Icons.timer_outlined,
                            duration,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: _infoText(
                            Icons.calendar_today_outlined,
                            date,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              // =========================================
              // STATUS + ARROW
              // =========================================

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusBadge(status),
                  const SizedBox(height: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey,
                    size: 19,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SMALL INFO ITEM
  // =====================================================

  Widget _infoText(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: AppColors.grey,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.slate,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // STATUS BADGE
  // =====================================================

  Widget _statusBadge(String status) {
    final String normalized =
        status.trim().toLowerCase();

    final bool isSuccess =
        normalized == 'completed' ||
        normalized == 'complete' ||
        normalized == 'done' ||
        normalized == 'finished' ||
        normalized == 'success' ||
        normalized == 'successful';

    final Color badgeColor =
        isSuccess
            ? AppColors.success
            : AppColors.warning;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 62,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: badgeColor,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // =====================================================
  // STRING HELPER
  // =====================================================

  String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result = value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // =====================================================
  // DISTANCE FORMAT
  // =====================================================

  String _formatDistance(dynamic value) {
    if (value == null) {
      return '--';
    }

    if (value is num) {
      return '${_formatNumber(value.toDouble())} km';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '--';
    }

    if (text.toLowerCase().contains('km')) {
      return text;
    }

    return '$text km';
  }

  // =====================================================
  // DURATION FORMAT
  // =====================================================

  String _formatDuration(dynamic value) {
    if (value == null) {
      return '--';
    }

    if (value is num) {
      return '${value.toInt()} mins';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '--';
    }

    return text;
  }

  // =====================================================
  // NUMBER FORMAT
  // =====================================================

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}
