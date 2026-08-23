import 'package:cloud_firestore/cloud_firestore.dart';

class HomePastWalk {
  final String documentId;
  final String walkId;
  final String ownerUid;
  final String walkerUid;
  final String walkerName;
  final String dogName;
  final double distanceKm;
  final int durationMinutes;
  final int steps;
  final DateTime date;
  final String timeFormatted;
  final String status;

  const HomePastWalk({
    required this.documentId,
    required this.walkId,
    required this.ownerUid,
    required this.walkerUid,
    required this.walkerName,
    required this.dogName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
    required this.date,
    required this.timeFormatted,
    required this.status,
  });

  factory HomePastWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return HomePastWalk(
      documentId: documentId,

      walkId: _string(
        data['Walkid'] ??
            data['walkId'] ??
            data['walkID'] ??
            data['id'] ??
            documentId,
        fallback: documentId,
      ),

      ownerUid: _string(
        data['ownerUid'] ??
            data['ownerUID'] ??
            data['ownerId'],
      ),

      walkerUid: _string(
        data['walkerUid'] ??
            data['walkerUID'] ??
            data['walkerId'],
      ),

      walkerName: _string(
        data['walkerName'],
        fallback: 'Walker',
      ),

      dogName: _string(
        data['dogName'] ??
            data['petName'],
        fallback: 'Pet',
      ),

      distanceKm: _distanceKm(
        data['distanceKm'] ??
            data['distance'] ??
            data['totalDistance'],
      ),

      durationMinutes: _durationMinutes(
        data['durationMinutes'] ??
            data['duration'] ??
            data['totalDuration'],
      ),

      steps: _intValue(
        data['steps'] ??
            data['totalSteps'],
      ),

      date: _dateValue(
        data['date'] ??
            data['walkDate'] ??
            data['createdAt'] ??
            data['completedAt'] ??
            data['endedAt'] ??
            data['startTime'],
      ),

      timeFormatted: _string(
        data['timeFormatted'] ??
            data['time'] ??
            data['formattedTime'],
        fallback: '--',
      ),

      status: _string(
        data['status'] ??
            data['walkStatus'],
        fallback: 'Completed',
      ),
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  // ============================================================
  // INT
  // ============================================================

  static int _intValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
        value.toString()
            .trim()
            .toLowerCase();

    if (text.isEmpty) {
      return 0;
    }

    text = text.replaceAll(',', '');

    final bool isMeters =
        text.contains('meter') ||
        text.endsWith(' m') ||
        text.endsWith('m');

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

    if (isMeters) {
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

    final String text =
        value.toString()
            .trim()
            .toLowerCase();

    if (text.isEmpty) {
      return 0;
    }

    final RegExp hoursRegex =
        RegExp(
      r'(\d+)\s*(hr|hrs|hour|hours)',
    );

    final RegExp minutesRegex =
        RegExp(
      r'(\d+)\s*(min|mins|minute|minutes)',
    );

    final RegExpMatch? hoursMatch =
        hoursRegex.firstMatch(text);

    final RegExpMatch? minutesMatch =
        minutesRegex.firstMatch(text);

    final int hours =
        hoursMatch == null
            ? 0
            : int.tryParse(
                  hoursMatch.group(1) ?? '',
                ) ??
                0;

    final int minutes =
        minutesMatch == null
            ? 0
            : int.tryParse(
                  minutesMatch.group(1) ?? '',
                ) ??
                0;

    if (hours > 0 || minutes > 0) {
      return (hours * 60) + minutes;
    }

    return int.tryParse(text) ?? 0;
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime _dateValue(
    dynamic value,
  ) {
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

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  String get formattedDistance {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    if (durationMinutes <= 0) {
      return '0 mins';
    }

    final int hours =
        durationMinutes ~/ 60;

    final int minutes =
        durationMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hrs $minutes mins';
    }

    if (hours > 0) {
      return '$hours hrs';
    }

    return '$minutes mins';
  }
}
