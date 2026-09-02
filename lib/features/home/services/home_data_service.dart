import '../models/home_live_walk.dart';

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
    final double km = _readDouble(value);

    return '${km.toStringAsFixed(1)} km';
  }

  // ============================================================
  // DURATION FORMATTER
  // ============================================================

  static String formatDuration(
    dynamic value,
  ) {
    final int minutes = _readInt(value);

    if (minutes <= 0) {
      return '0 mins';
    }

    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      if (remainingMinutes == 0) {
        return '$hours hrs';
      }

      return '$hours hrs $remainingMinutes mins';
    }

    return '$minutes mins';
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  static double _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text = value
        .toString()
        .trim()
        .replaceAll(',', '');

    if (text.isEmpty) {
      return 0.0;
    }

    final Match? match = RegExp(
      r'-?\d+(?:\.\d+)?',
    ).firstMatch(text);

    if (match == null) {
      return 0.0;
    }

    return double.tryParse(
          match.group(0)!,
        ) ??
        0.0;
  }

  // ============================================================
  // SAFE INTEGER
  // ============================================================

  static int _readInt(
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

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    final Match? match = RegExp(
      r'-?\d+(?:\.\d+)?',
    ).firstMatch(text);

    if (match == null) {
      return 0;
    }

    return double.tryParse(
          match.group(0)!,
        )?.round() ??
        0;
  }
}
