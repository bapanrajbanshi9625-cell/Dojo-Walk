import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalk {
  final String id;
  final String requestId;
  final String ownerId;
  final String walkerId;
  final String walkerName;
  final String walkerPhone;
  final String petName;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActiveWalk({
    required this.id,
    this.requestId = '',
    this.ownerId = '',
    this.walkerId = '',
    this.walkerName = '',
    this.walkerPhone = '',
    this.petName = '',
    this.status = '',
    this.createdAt,
    this.updatedAt,
  });

  ActiveWalk copyWith({
    String? id,
    String? requestId,
    String? ownerId,
    String? walkerId,
    String? walkerName,
    String? walkerPhone,
    String? petName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActiveWalk(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      ownerId: ownerId ?? this.ownerId,
      walkerId: walkerId ?? this.walkerId,
      walkerName: walkerName ?? this.walkerName,
      walkerPhone: walkerPhone ?? this.walkerPhone,
      petName: petName ?? this.petName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ActiveWalk.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ActiveWalk(
      id: documentId,
      requestId: _readString(
        data,
        const [
          'requestId',
          'walkRequestId',
          'requestID',
        ],
      ),
      ownerId: _readString(
        data,
        const [
          'ownerId',
          'ownerID',
        ],
      ),
      walkerId: _readString(
        data,
        const [
          'walkerId',
          'walkerID',
        ],
      ),
      walkerName: _readString(
        data,
        const [
          'walkerName',
          'Walker Name',
        ],
      ),
      walkerPhone: _readString(
        data,
        const [
          'walkerPhone',
          'walkerMobile',
          'phone',
          'mobile',
        ],
      ),
      petName: _readString(
        data,
        const [
          'petName',
          'dogName',
          'Pet Name',
          'Dog Name',
        ],
      ),
      status: _readString(
        data,
        const [
          'status',
        ],
      ),
      createdAt: _readDateTime(
        data['createdAt'],
      ),
      updatedAt: _readDateTime(
        data['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'ownerId': ownerId,
      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerPhone': walkerPhone,
      'petName': petName,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String result = value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
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
