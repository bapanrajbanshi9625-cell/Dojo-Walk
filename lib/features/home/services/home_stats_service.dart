import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_past_walk_service.dart';

class HomeStatsService {
  HomeStatsService._();

  static final HomeStatsService instance =
      HomeStatsService._();

  final HomePastWalkService _pastWalkService =
      HomePastWalkService.instance;

  // ============================================================
  // WEEKLY STATS
  // ============================================================

  Future<HomeWeeklyStats> getWeeklyStats() async {
    final List<Map<String, dynamic>> walks =
        await _pastWalkService.getPastWalks(
      limit: 100,
    );

    final DateTime now = DateTime.now();

    final DateTime startOfWeek =
        DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(
      Duration(
        days: now.weekday - 1,
      ),
    );

    final List<Map<String, dynamic>> weeklyWalks =
        walks.where(
      (Map<String, dynamic> walk) {
        final DateTime date =
            _dateFromMap(walk);

        return !date.isBefore(
          startOfWeek,
        );
      },
    ).toList();

    double totalDistance = 0;

    int totalDuration = 0;

    for (
      final Map<String, dynamic> walk
          in weeklyWalks
    ) {
      totalDistance +=
          _distanceKm(
        walk['distance'] ??
            walk['distanceKm'] ??
            walk['totalDistance'],
      );

      totalDuration +=
          _durationMinutes(
        walk['duration'] ??
            walk['durationMinutes'] ??
            walk['totalDuration'],
      );
    }

    return HomeWeeklyStats(
      totalWalks: weeklyWalks.length,
      totalDistanceKm: totalDistance,
      totalDurationMinutes: totalDuration,
      walks: weeklyWalks,
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  static double _distanceKm(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    String text =
        value.toString().trim().toLowerCase();

    if (text.isEmpty) {
      return 0;
    }

    text = text.replaceAll(',', '');

    final bool meters =
        text.contains('meter') ||
        text.contains(' m');

    text = text
        .replaceAll('kilometers', '')
        .replaceAll('kilometer', '')
        .replaceAll('kms', '')
        .replaceAll('km', '')
        .replaceAll('meters', '')
        .replaceAll('meter', '')
        .replaceAll('m', '')
        .trim();

    final double parsed =
        double.tryParse(text) ?? 0;

    if (meters) {
      return parsed / 1000;
    }

    return parsed;
  }

  // ============================================================
  // DURATION
  // ============================================================

  static int _durationMinutes(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    String text =
        value.toString().trim().toLowerCase();

    if (text.isEmpty) {
      return 0;
    }

    // ----------------------------------------------------------
    // "45 mins"
    // ----------------------------------------------------------

    final RegExp minsRegex =
        RegExp(r'(\d+)\s*(min|mins|minute|minutes)');

    final RegExpMatch? minsMatch =
        minsRegex.firstMatch(text);

    if (minsMatch != null) {
      return int.tryParse(
            minsMatch.group(1) ?? '',
          ) ??
          0;
    }

    // ----------------------------------------------------------
    // "1 hr 20 mins"
    // ----------------------------------------------------------

    final RegExp hoursRegex =
        RegExp(r'(\d+)\s*(hr|hrs|hour|hours)');

    final RegExpMatch? hoursMatch =
        hoursRegex.firstMatch(text);

    if (hoursMatch != null) {
      final int hours =
          int.tryParse(
                hoursMatch.group(1) ?? '',
              ) ??
              0;

      final RegExpMatch? minuteMatch =
          minsRegex.firstMatch(text);

      final int minutes =
          minuteMatch == null
              ? 0
              : int.tryParse(
                    minuteMatch.group(1) ?? '',
                  ) ??
                  0;

      return hours * 60 + minutes;
    }

    return int.tryParse(text) ?? 0;
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime _dateFromMap(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['date'] ??
            data['createdAt'] ??
            data['completedAt'] ??
            data['endedAt'] ??
            data['startTime'] ??
            data['timestamp'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

// ============================================================
// WEEKLY STATS MODEL
// ============================================================

class HomeWeeklyStats {
  final int totalWalks;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<Map<String, dynamic>> walks;

  const HomeWeeklyStats({
    required this.totalWalks,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.walks,
  });

  String get formattedDistance {
    if (totalDistanceKm <= 0) {
      return '0.0 km';
    }

    return '${totalDistanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (totalDurationMinutes <= 0) {
      return '0 mins';
    }

    final int hours =
        totalDurationMinutes ~/ 60;

    final int minutes =
        totalDurationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs $minutes mins';
    }

    if (hours > 0) {
      return '$hours hrs';
    }

    return '$minutes mins';
  }

  double get averageDistance {
    if (totalWalks == 0) {
      return 0;
    }

    return totalDistanceKm / totalWalks;
  }

  int get averageDuration {
    if (totalWalks == 0) {
      return 0;
    }

    return totalDurationMinutes ~/ totalWalks;
  }
}
