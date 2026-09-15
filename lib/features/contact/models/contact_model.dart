import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  const ContactModel({
    required this.contactId,
    required this.walkId,
    required this.requestId,
    required this.sessionId,
    required this.ownerUid,
    required this.walkerUid,
    required this.ownerPhone,
    required this.walkerPhone,
    required this.status,
  });

  final String contactId;
  final String walkId;
  final String requestId;
  final String sessionId;
  final String ownerUid;
  final String walkerUid;
  final String ownerPhone;
  final String walkerPhone;
  final String status;

  factory ContactModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ContactModel(
      contactId: map['contactId']?.toString() ?? '',
      walkId: map['walkId']?.toString() ?? '',
      requestId: map['requestId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      ownerUid: map['ownerUid']?.toString() ?? '',
      walkerUid: map['walkerUid']?.toString() ?? '',
      ownerPhone: map['ownerPhone']?.toString() ?? '',
      walkerPhone: map['walkerPhone']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'contactId': contactId,
      'walkId': walkId,
      'requestId': requestId,
      'sessionId': sessionId,
      'ownerUid': ownerUid,
      'walkerUid': walkerUid,
      'ownerPhone': ownerPhone,
      'walkerPhone': walkerPhone,
      'status': status,
    };
  }
}

class ContactMessage {
  const ContactMessage({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.text,
    required this.createdAt,
    required this.type,
    required this.mediaUrl,
    required this.durationSeconds,
  });

  final String id;
  final String senderUid;
  final String receiverUid;
  final String text;
  final DateTime? createdAt;

  /// Message type:
  /// text / image / video / voice
  final String type;

  /// Image, video or voice download URL.
  final String? mediaUrl;

  /// Voice message duration in seconds.
  final int? durationSeconds;

  factory ContactMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    final dynamic timestamp = data['createdAt'];

    final dynamic durationValue =
        data['durationSeconds'];

    int? durationSeconds;

    if (durationValue is int) {
      durationSeconds = durationValue;
    } else if (durationValue is num) {
      durationSeconds = durationValue.toInt();
    } else if (durationValue != null) {
      durationSeconds =
          int.tryParse(durationValue.toString());
    }

    final String rawType =
        data['type']?.toString().trim().toLowerCase() ?? '';

    final String messageType =
        rawType.isEmpty ? 'text' : rawType;

    final String? mediaUrl =
        data['mediaUrl']?.toString().trim().isNotEmpty == true
            ? data['mediaUrl'].toString().trim()
            : null;

    return ContactMessage(
      id: document.id,
      senderUid: data['senderUid']?.toString() ?? '',
      receiverUid: data['receiverUid']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : null,
      type: messageType,
      mediaUrl: mediaUrl,
      durationSeconds: durationSeconds,
    );
  }
}
