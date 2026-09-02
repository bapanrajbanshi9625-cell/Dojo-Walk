import 'home_owner_service.dart';
import 'home_past_walk_service.dart';
import 'home_stats_service.dart';

class HomeDataService {
  HomeDataService._();

  static final HomeDataService instance =
      HomeDataService._();

  final HomeOwnerService ownerService =
      HomeOwnerService.instance;

  final HomePastWalkService pastWalkService =
      HomePastWalkService.instance;

  final HomeStatsService statsService =
      HomeStatsService.instance;

  // ============================================================
  // OWNER
  // ============================================================

  Future<String?> getOwnerId() {
    return ownerService.getOwnerId();
  }

  Future<Map<String, dynamic>?> getOwnerProfile() {
    return ownerService.getOwnerProfile();
  }

  Future<String> getOwnerName() {
    return ownerService.getOwnerName();
  }

  Future<List<Map<String, dynamic>>> getPets() {
    return ownerService.getPets();
  }

  // ============================================================
  // PAST WALKS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPastWalks({
    int limit = 20,
  }) {
    return pastWalkService.getPastWalks(
      limit: limit,
    );
  }

  Stream<List<Map<String, dynamic>>> pastWalksStream({
    int limit = 20,
  }) {
    return pastWalkService.stream(
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> getWalkById(
    String walkId,
  ) {
    return pastWalkService.getWalkById(
      walkId,
    );
  }

  // ============================================================
  // WEEKLY STATS
  // ============================================================

  Future<HomeWeeklyStats> getWeeklyStats() {
    return statsService.getWeeklyStats();
  }

  // ============================================================
  // DISTANCE FORMATTER
  // ============================================================

  static String formatDistance(
    dynamic value,
  ) {
    final double km = _readDistanceKm(value);

    return '${km.toStringAsFixed(1)} km';
  }

  // ============================================================
  // DURATION FORMATTER
  // ============================================================

  static String formatDuration(
    dynamic value,
  ) {
    final int minutes = _readDurationMinutes(value);

    if (minutes <= 0) {
      return '0 mins';
    }

    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '$hours hrs $remainingMinutes mins';
    }

    if (hours > 0) {
      return '$hours hrs';
    }

    return '$minutes mins';
  }

  // ============================================================
  // SAFE DISTANCE
  // ============================================================

  static double _readDistanceKm(
    dynamic value,
  ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    String text = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(',', '');

    if (text.isEmpty) {
      return 0.0;
    }

    final bool isMeters =
        text.contains('meter') ||
        RegExp(r'\bm\b').hasMatch(text);

    final Match? match = RegExp(
      r'-?\d+(?:\.\d+)?',
    ).firstMatch(text);

    if (match == null) {
      return 0.0;
    }

    final double parsed =
        double.tryParse(match.group(0) ?? '') ?? 0.0;

    if (isMeters) {
      return parsed / 1000;
    }

    return parsed;
  }

  // ============================================================
  // SAFE DURATION
  // ============================================================

  static int _readDurationMinutes(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    final String text =
        value.toString().trim().toLowerCase();

    if (text.isEmpty) {
      return 0;
    }

    // ----------------------------------------------------------
    // HOURS
    // ----------------------------------------------------------

    final RegExpMatch? hoursMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(hr|hrs|hour|hours)',
    ).firstMatch(text);

    final RegExpMatch? minutesMatch = RegExp(
      r'(\d+)\s*(min|mins|minute|minutes)',
    ).firstMatch(text);

    if (hoursMatch != null) {
      final double hours =
          double.tryParse(
                hoursMatch.group(1) ?? '',
              ) ??
              0.0;

      final int minutes = minutesMatch == null
          ? 0
          : int.tryParse(
                minutesMatch.group(1) ?? '',
              ) ??
              0;

      return (hours * 60).round() + minutes;
    }

    // ----------------------------------------------------------
    // MINUTES
    // ----------------------------------------------------------

    if (minutesMatch != null) {
      return int.tryParse(
            minutesMatch.group(1) ?? '',
          ) ??
          0;
    }

    // ----------------------------------------------------------
    // PLAIN NUMBER
    // ----------------------------------------------------------

    final Match? numberMatch = RegExp(
      r'-?\d+(?:\.\d+)?',
    ).firstMatch(text);

    if (numberMatch == null) {
      return 0;
    }

    return double.tryParse(
          numberMatch.group(0) ?? '',
        )?.round() ??
        0;
  }
}
