import 'home_past_walk.dart';

class HomeWeeklyStats {
  final int totalWalks;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<HomePastWalk> walks;

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
      return '0 hrs';
    }

    final int hours =
        totalDurationMinutes ~/ 60;

    final int minutes =
        totalDurationMinutes % 60;

    if (hours == 0) {
      return '$minutes mins';
    }

    if (minutes == 0) {
      return '$hours hrs';
    }

    return '$hours hrs $minutes mins';
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
