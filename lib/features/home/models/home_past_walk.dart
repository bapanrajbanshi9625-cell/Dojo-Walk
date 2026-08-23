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
    final dynamic dateValue =
        data['date'] ??
        data['createdAt'] ??
        data['completedAt'] ??
        data['endedAt'] ??
        data['startTime'];

    final dynamic distanceValue =
        data['distanceKm'] ??
        data['distance'] ??
        data['totalDistance'];

    final dynamic durationValue =
        data['durationMinutes'] ??
        data['duration'] ??
        data['totalDuration'];

    final dynamic stepsValue =
        data['steps'] ??
        data['totalSteps'];

    return HomePastWalk(
      documentId: documentId,

      walkId: _string(
        data['walkId'] ??
            data['Walkid'] ??
            data['id'] ??
            documentId,
      ),

      ownerUid: _string(
        data['ownerId'] ??
            data['ownerUid'] ??
            data['ownerAuthUid'],
      ),

      walkerUid: _string(
        data['walkerUid'] ??
            data['walkerId'],
      ),

      walkerName: _string(
        data['walkerName'] ??
            data['walker'],
        fallback: 'Walker',
      ),

      dogName: _string(
        data['dogName'] ??
            data['petName'],
      ),

      distanceKm: _double(
        distanceValue,
      ),

      durationMinutes: _int(
        durationValue,
      ),

      steps: _int(
        stepsValue,
      ),

      date: _date(
        dateValue,
      ),

      timeFormatted: _string(
        data['timeFormatted'] ??
            data['time'] ??
            data['formattedTime'],
      ),

      status: _string(
        data['status'] ??
            data['walkStatus'],
        fallback: 'Completed',
      ),
    );
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().replaceAll(',', '') ?? '',
        ) ??
        0;
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime _date(dynamic value) {
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
