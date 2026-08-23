import 'package:cloud_firestore/cloud_firestore.dart';

class HomeLiveWalk {
  final String documentId;
  final String walkId;
  final String ownerId;
  final String walkerId;
  final String walkerName;
  final String? walkerPhone;
  final String status;
  final DateTime? startedAt;
  final double currentLat;
  final double currentLng;

  const HomeLiveWalk({
    required this.documentId,
    required this.walkId,
    required this.ownerId,
    required this.walkerId,
    required this.walkerName,
    required this.walkerPhone,
    required this.status,
    required this.startedAt,
    required this.currentLat,
    required this.currentLng,
  });

  factory HomeLiveWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final String phone = _string(
      data['walkerPhone'] ??
          data['walkerMobile'] ??
          data['phone'],
    );

    return HomeLiveWalk(
      documentId: documentId,

      walkId: _string(
        data['walkId'] ??
            data['Walkid'] ??
            data['id'] ??
            documentId,
      ),

      ownerId: _string(
        data['ownerId'],
      ),

      walkerId: _string(
        data['walkerId'] ??
            data['walkerUid'] ??
            data['walkerUID'],
      ),

      walkerName: _string(
        data['walkerName'],
        fallback: 'Walker',
      ),

      walkerPhone: phone.isEmpty ? null : phone,

      status: _string(
        data['status'] ??
            data['walkStatus'] ??
            data['currentStatus'],
        fallback: 'active',
      ),

      startedAt: _date(
        data['startedAt'] ??
            data['startTime'] ??
            data['started_at'],
      ),

      currentLat: _double(
        data['currentLat'] ??
            data['latitude'],
      ),

      currentLng: _double(
        data['currentLng'] ??
            data['longitude'],
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

    final String result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().trim() ?? '',
        ) ??
        0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
