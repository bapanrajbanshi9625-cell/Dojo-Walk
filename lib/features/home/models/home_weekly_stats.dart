class HomeWeeklyStats {
  // ============================================================
  // DATA
  // ============================================================

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

  // ============================================================
  // FORMATTED DISTANCE
  // ============================================================

  String get formattedDistance {
    if (totalDistanceKm <= 0) {
      return '0.0 km';
    }

    return '${totalDistanceKm.toStringAsFixed(1)} km';
  }

  // ============================================================
  // FORMATTED DURATION
  // ============================================================

  String get formattedDuration {
    if (totalDurationMinutes <= 0) {
      return '0 mins';
    }

    final int hours = totalDurationMinutes ~/ 60;
    final int minutes = totalDurationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs $minutes mins';
    }

    if (hours > 0) {
      return '$hours hrs';
    }

    return '$minutes mins';
  }

  // ============================================================
  // AVERAGE DISTANCE
  // ============================================================

  double get averageDistance {
    if (totalWalks <= 0) {
      return 0.0;
    }

    return totalDistanceKm / totalWalks;
  }

  // ============================================================
  // AVERAGE DURATION
  // ============================================================

  int get averageDuration {
    if (totalWalks <= 0) {
      return 0;
    }

    return totalDurationMinutes ~/ totalWalks;
  }
}
