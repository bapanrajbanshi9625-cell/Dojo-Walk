import 'package:cloud_firestore/cloud_firestore.dart';

class HomeLiveWalk {
  final String documentId;
  final String walkId;
  final String ownerUid;
  final String walkerUid;
  final String walkerName;
  final String? walkerPhone;
  final String status;
  final DateTime? startedAt;

  const HomeLiveWalk({
    required this.documentId,
    required this.walkId,
    required this.ownerUid,
    required this.walkerUid,
    required this.walkerName,
    required this.walkerPhone,
    required this.status,
    required this.startedAt,
  });

  factory HomeLiveWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final String phone = _string(
      data['walkerPhone'] ??
          data['walkerMobile'] ??
          data['phone'] ??
          data['phoneNumber'],
    );

    return HomeLiveWalk(
      documentId: documentId,
      walkId: _string(
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
        data['walkerName'] ??
            data['name'],
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
    );
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    return text.isEmpty ? fallback : text;
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
