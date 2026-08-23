import '../models/home_live_walk.dart';

import 'home_live_walk_service.dart';
import 'home_owner_service.dart';
import 'home_past_walk_service.dart';
import 'home_stats_service.dart';

class HomeDataService {
  HomeDataService._();

  static final HomeDataService instance =
      HomeDataService._();

  final HomeOwnerService ownerService =
      HomeOwnerService.instance;

  final HomeLiveWalkService liveWalkService =
      HomeLiveWalkService.instance;

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
  // LIVE WALK
  // ============================================================

  Stream<HomeLiveWalk?> liveWalkStream() {
    return liveWalkService.stream();
  }

  Future<HomeLiveWalk?> getCurrentLiveWalk() {
    return liveWalkService.getCurrentWalk();
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
  // WEEKLY
  // ============================================================

  Future<HomeWeeklyStats> getWeeklyStats() {
    return statsService.getWeeklyStats();
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  static String formatDistance(
    dynamic value,
  ) {
    if (value == null) {
      return '0.0 km';
    }

    double km;

    if (value is num) {
      km = value.toDouble();
    } else {
      km =
          double.tryParse(
                value
                    .toString()
                    .replaceAll(',', '')
                    .replaceAll(
                      RegExp(
                        r'[^0-9.\-]',
                      ),
                      '',
                    ),
              ) ??
              0;
    }

    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(
    dynamic value,
  ) {
    if (value == null) {
      return '0 mins';
    }

    final int minutes =
        value is num
            ? value.toInt()
            : int.tryParse(
                  value.toString(),
                ) ??
                0;

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
