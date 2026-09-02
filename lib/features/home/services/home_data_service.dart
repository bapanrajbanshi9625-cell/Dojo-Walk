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
  // STATUS
  // ============================================================

  static const Set<String> inactiveStatuses = {
    'completed',
    'complete',
    'cancelled',
    'canceled',
    'ended',
    'finished',
    'rejected',
    'declined',
  };

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

  /// Converts the raw Firestore stream from
  /// HomeLiveWalkService into a typed HomeLiveWalk stream.
  ///
  /// Completed/cancelled/ended walks are ignored.
  Stream<HomeLiveWalk?> liveWalkStream() async* {
    await for (final snapshot in liveWalkService.stream()) {
      HomeLiveWalk? liveWalk;

      for (final doc in snapshot.docs) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(
          doc.data(),
        );

        final String status = _readStatus(data);

        if (inactiveStatuses.contains(status)) {
          continue;
        }

        liveWalk = HomeLiveWalk.fromFirestore(
          doc.id,
          data,
        );

        break;
      }

      yield liveWalk;
    }
  }

  // ============================================================
  // CURRENT LIVE WALK
  // ============================================================

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
  // PRIVATE STATUS READER
  // ============================================================

  static String _readStatus(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['status'] ??
        data['walkStatus'] ??
        data['currentStatus'];

    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toLowerCase();
  }

  // ============================================================
  // SAFE DOUBLE PARSER
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
  // SAFE INTEGER PARSER
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
