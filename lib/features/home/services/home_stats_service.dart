import 'home_owner_service.dart';
import 'home_past_walk_service.dart';

import '../models/home_past_walk.dart';
import '../models/home_weekly_stats.dart';

class HomeStatsService {
  HomeStatsService._();

  static final HomeStatsService instance =
      HomeStatsService._();

  final HomePastWalkService _pastWalkService =
      HomePastWalkService.instance;

  // Kept here so the service has one owner-aware
  // dependency chain.
  final HomeOwnerService _ownerService =
      HomeOwnerService.instance;

  Future<HomeWeeklyStats> getWeeklyStats() async {
    // Ensure current owner exists.
    final String? ownerId =
        await _ownerService.getOwnerId();

    if (ownerId == null) {
      return const HomeWeeklyStats(
        totalWalks: 0,
        totalDistanceKm: 0,
        totalDurationMinutes: 0,
        walks: <HomePastWalk>[],
      );
    }

    final List<HomePastWalk> walks =
        await _pastWalkService.getPastWalks(
      limit: 100,
    );

    final DateTime now =
        DateTime.now();

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

    final List<HomePastWalk> weeklyWalks =
        walks.where(
      (HomePastWalk walk) {
        return !walk.date.isBefore(
          startOfWeek,
        );
      },
    ).toList();

    double distance = 0;
    int duration = 0;

    for (
      final HomePastWalk walk
          in weeklyWalks
    ) {
      distance += walk.distanceKm;
      duration += walk.durationMinutes;
    }

    return HomeWeeklyStats(
      totalWalks: weeklyWalks.length,
      totalDistanceKm: distance,
      totalDurationMinutes: duration,
      walks: weeklyWalks,
    );
  }
}
