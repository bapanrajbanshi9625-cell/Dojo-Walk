
import '../models/home_past_walk.dart';
import '../models/home_weekly_stats.dart';

import 'home_past_walk_service.dart';
import 'home_stats_service.dart';

export '../models/home_live_walk.dart';
export '../models/home_past_walk.dart';
export '../models/home_weekly_stats.dart';

class HomeDataService {
  HomeDataService._();

  static final HomeDataService instance =
      HomeDataService._();

  final HomeLiveWalkService _live =
      HomeLiveWalkService.instance;

  final HomePastWalkService _past =
      HomePastWalkService.instance;

  final HomeStatsService _stats =
      HomeStatsService.instance;

  // ==========================================================
  // LIVE WALK
  // ==========================================================

  Stream<HomeLiveWalk?> liveWalkStream() {
    return _live.liveWalkStream();
  }

  // ==========================================================
  // PAST WALKS
  // ==========================================================

  Future<List<HomePastWalk>> getPastWalks({
    int limit = 20,
  }) {
    return _past.getPastWalks(
      limit: limit,
    );
  }

  Stream<List<HomePastWalk>> pastWalksStream({
    int limit = 20,
  }) {
    return _past.pastWalksStream(
      limit: limit,
    );
  }

  // ==========================================================
  // WEEKLY STATS
  // ==========================================================

  Future<HomeWeeklyStats> getWeeklyStats() {
    return _stats.getWeeklyStats();
  }

  // ==========================================================
  // FORMATTERS
  // ==========================================================

  static String formatDistance(
    double km,
  ) {
    if (km <= 0) {
      return '0.0 km';
    }

    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(
    int minutes,
  ) {
    if (minutes <= 0) {
      return '0 mins';
    }

    final int hours =
        minutes ~/ 60;

    final int remaining =
        minutes % 60;

    if (hours > 0) {
      if (remaining == 0) {
        return '$hours hrs';
      }

      return '$hours hrs $remaining mins';
    }

    return '$minutes mins';
  }
}
