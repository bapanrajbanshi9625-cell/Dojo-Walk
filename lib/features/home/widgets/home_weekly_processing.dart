import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class HomeWeeklyProcessing extends StatelessWidget {
  const HomeWeeklyProcessing({
    super.key,
    required this.onDetails,
  });

  final void Function(
    String title,
    String content,
  ) onDetails;

  // ==========================================================
  // CURRENT OWNER UID
  // ==========================================================

  String? get _ownerUid {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final uid = _ownerUid;

    if (uid == null) {
      return _buildWithData(
        totalWalks: 0,
        totalDistance: 0,
        averageDistance: 0,
        longestDistance: 0,
        totalDurationMinutes: 0,
        averageDurationMinutes: 0,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('walk_history')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildWithData(
            totalWalks: 0,
            totalDistance: 0,
            averageDistance: 0,
            longestDistance: 0,
            totalDurationMinutes: 0,
            averageDurationMinutes: 0,
          );
        }

        final documents = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final weeklyData = _calculateCurrentWeek(
          documents,
          uid,
        );

        return _buildWithData(
          totalWalks: weeklyData.totalWalks,
          totalDistance: weeklyData.totalDistance,
          averageDistance: weeklyData.averageDistance,
          longestDistance: weeklyData.longestDistance,
          totalDurationMinutes:
              weeklyData.totalDurationMinutes,
          averageDurationMinutes:
              weeklyData.averageDurationMinutes,
        );
      },
    );
  }

  // ==========================================================
  // CURRENT WEEK
  // MONDAY -> SUNDAY
  // ==========================================================

  _WeeklyData _calculateCurrentWeek(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String currentUid,
  ) {
    final now = DateTime.now();

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final weekStart = startOfToday.subtract(
      Duration(
        days: startOfToday.weekday - DateTime.monday,
      ),
    );

    final nextWeekStart = weekStart.add(
      const Duration(days: 7),
    );

    int totalWalks = 0;
    double totalDistance = 0;
    double longestDistance = 0;
    int totalDurationMinutes = 0;

    for (final document in documents) {
      final data = document.data();

      final ownerId = _readString(
        data['ownerId'],
      );

      if (ownerId != currentUid) {
        continue;
      }

      final completedAt = _readDateTime(
        data['completedAt'],
      );

      if (completedAt == null) {
        continue;
      }

      if (completedAt.isBefore(weekStart) ||
          !completedAt.isBefore(nextWeekStart)) {
        continue;
      }

      final status = _readString(
        data['status'],
      ).toLowerCase();

      if (status.isNotEmpty) {
        const completedStatuses = {
          'completed',
          'complete',
          'done',
          'finished',
          'success',
          'successful',
        };

        if (!completedStatuses.contains(status)) {
          continue;
        }
      }

      totalWalks++;

      final distance = _readDouble(
        data['distance'],
      );

      if (distance != null && distance >= 0) {
        totalDistance += distance;

        if (distance > longestDistance) {
          longestDistance = distance;
        }
      }

      final durationMinutes = _readDurationMinutes(
        data,
      );

      if (durationMinutes != null &&
          durationMinutes >= 0) {
        totalDurationMinutes += durationMinutes;
      }
    }

    final averageDistance = totalWalks == 0
        ? 0.0
        : totalDistance / totalWalks;

    final averageDurationMinutes = totalWalks == 0
        ? 0
        : (totalDurationMinutes / totalWalks).round();

    return _WeeklyData(
      totalWalks: totalWalks,
      totalDistance: totalDistance,
      averageDistance: averageDistance,
      longestDistance: longestDistance,
      totalDurationMinutes: totalDurationMinutes,
      averageDurationMinutes: averageDurationMinutes,
    );
  }

  // ==========================================================
  // COMPACT WEEKLY UI
  // ==========================================================

  Widget _buildWithData({
    required int totalWalks,
    required double totalDistance,
    required double averageDistance,
    required double longestDistance,
    required int totalDurationMinutes,
    required int averageDurationMinutes,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        9,
        10,
        9,
        10,
      ),
      decoration: BoxDecoration(
        color: DojoWalkColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DojoWalkColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _compactItem(
              title: 'Walks',
              value: '$totalWalks',
              icon: Icons.pets_rounded,
              iconColor: DojoWalkColors.primary,
              onTap: () {
                onDetails(
                  'Walks Details',
                  'Completed Walks: $totalWalks\n'
                  'Average Walks/Day: '
                  '${_averageWalksPerDay(totalWalks)}\n'
                  'Status: ${_walkStatus(totalWalks)}',
                );
              },
            ),
          ),
          _divider(),
          Expanded(
            child: _compactItem(
              title: 'Distance',
              value: _formatNumber(totalDistance),
              unit: 'km',
              icon: Icons.route_rounded,
              iconColor: DojoWalkColors.blue,
              onTap: () {
                onDetails(
                  'Distance Details',
                  'Total Distance: '
                  '${_formatNumber(totalDistance)} km\n'
                  'Average per Walk: '
                  '${_formatNumber(averageDistance)} km\n'
                  'Longest Walk: '
                  '${_formatNumber(longestDistance)} km',
                );
              },
            ),
          ),
          _divider(),
          Expanded(
            child: _compactItem(
              title: 'Duration',
              value: _compactDuration(
                totalDurationMinutes,
              ),
              icon: Icons.timer_outlined,
              iconColor: DojoWalkColors.green,
              onTap: () {
                onDetails(
                  'Duration Details',
                  'Total Active Time: '
                  '${_formatDuration(totalDurationMinutes)}\n'
                  'Average Duration per Walk: '
                  '${_formatDuration(averageDurationMinutes)}\n'
                  'Pace Efficiency: '
                  '${_paceStatus(averageDurationMinutes)}',
                );
              },
            ),
          ),
          _divider(),
          Expanded(
            child: _compactItem(
              title: 'Report',
              value: totalWalks > 0 ? 'Active' : 'None',
              icon: Icons.assessment_outlined,
              iconColor: DojoWalkColors.primary,
              onTap: () {
                final reportStatus =
                    totalWalks > 0 ? 'Active' : 'No Walks';

                onDetails(
                  'Weekly Report',
                  'Current Week Report: '
                  '$reportStatus ($totalWalks Walks)\n\n'
                  'Weekly Cycle: Monday - Sunday\n\n'
                  'Counting resets automatically every Monday.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPACT ITEM
  // ==========================================================

  Widget _compactItem({
    required String title,
    required String value,
    String unit = '',
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: DojoWalkColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DojoWalkColors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 1),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DojoWalkColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _divider() {
    return Container(
      width: 1,
      height: 55,
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      color: DojoWalkColors.border.withValues(
        alpha: 0.75,
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final cleaned = value
          .trim()
          .replaceAll(',', '')
          .replaceAll('km', '')
          .trim();

      return double.tryParse(cleaned);
    }

    return null;
  }

  static int? _readDurationMinutes(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['durationMinutes'],
      data['durationInMinutes'],
      data['duration'],
    ];

    for (final value in candidates) {
      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.round();
      }

      if (value is String) {
        final text = value.trim().toLowerCase();

        final direct = int.tryParse(text);

        if (direct != null) {
          return direct;
        }

        final hourMatch = RegExp(
          r'(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)',
        ).firstMatch(text);

        final minuteMatch = RegExp(
          r'(\d+)\s*(?:m|min|mins|minute|minutes)',
        ).firstMatch(text);

        double totalMinutes = 0;

        if (hourMatch != null) {
          totalMinutes +=
              double.parse(hourMatch.group(1)!) * 60;
        }

        if (minuteMatch != null) {
          totalMinutes +=
              double.parse(minuteMatch.group(1)!);
        }

        if (totalMinutes > 0) {
          return totalMinutes.round();
        }
      }
    }

    return null;
  }

  static String _formatNumber(double value) {
    if (value == 0) {
      return '0';
    }

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  static String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return '0 hrs';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes mins';
    }

    if (remainingMinutes == 0) {
      return '$hours hrs';
    }

    return '$hours h ${remainingMinutes}m';
  }

  static String _compactDuration(int minutes) {
    if (minutes <= 0) {
      return '0h';
    }

    final hours = minutes ~/ 60;
    final remaining = minutes % 60;

    if (hours == 0) {
      return '${remaining}m';
    }

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h';
  }

  static String _averageWalksPerDay(int totalWalks) {
    if (totalWalks == 0) {
      return '0';
    }

    final now = DateTime.now();
    final daysSoFar = now.weekday;
    final average = totalWalks / daysSoFar;

    return average.toStringAsFixed(1);
  }

  static String _walkStatus(int totalWalks) {
    if (totalWalks == 0) {
      return 'No Walks';
    }

    return 'On Track';
  }

  static String _paceStatus(int averageDurationMinutes) {
    if (averageDurationMinutes <= 0) {
      return 'No Data';
    }

    if (averageDurationMinutes <= 45) {
      return 'Good';
    }

    if (averageDurationMinutes <= 90) {
      return 'Normal';
    }

    return 'Long Walks';
  }
}

// ==========================================================
// WEEKLY DATA MODEL
// ==========================================================

class _WeeklyData {
  const _WeeklyData({
    required this.totalWalks,
    required this.totalDistance,
    required this.averageDistance,
    required this.longestDistance,
    required this.totalDurationMinutes,
    required this.averageDurationMinutes,
  });

  final int totalWalks;
  final double totalDistance;
  final double averageDistance;
  final double longestDistance;
  final int totalDurationMinutes;
  final int averageDurationMinutes;
}
