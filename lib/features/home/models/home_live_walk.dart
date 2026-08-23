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

  const HomeLiveWalk({
    required this.documentId,
    required this.walkId,
    required this.ownerId,
    required this.walkerId,
    required this.walkerName,
    required this.walkerPhone,
    required this.status,
    required this.startedAt,
  });

  factory HomeLiveWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dynamic startedAtValue =
        data['startedAt'] ??
        data['startTime'] ??
        data['started_at'];

    final String walkerName =
        _string(
          data['walkerName'] ??
              data['walker'],
          fallback: 'Walker',
        );

    final String walkerPhone =
        _string(
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
        data['ownerId'] ??
            data['ownerUid'],
      ),

      walkerId: _string(
        data['walkerId'] ??
            data['walkerUid'] ??
            data['walkerUID'],
      ),

      walkerName: walkerName,

      walkerPhone:
          walkerPhone.isEmpty
              ? null
              : walkerPhone,

      status: _string(
        data['status'] ??
            data['walkStatus'] ??
            data['currentStatus'],
        fallback: 'active',
      ),

      startedAt:
          startedAtValue == null
              ? null
              : _date(startedAtValue),
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

    return result.isEmpty
        ? fallback
        : result;
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
