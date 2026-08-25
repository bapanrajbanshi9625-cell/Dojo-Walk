import 'package:cloud_firestore/cloud_firestore.dart';

// ==================================================================
// SEARCH RESULT
// ==================================================================

class InstaWalkSearchResult {
  final bool success;
  final String? requestId;
  final DateTime? expiresAt;
  final Duration? duration;
  final int? searchNumber;
  final String? message;
  final String? errorCode;

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.duration,
    this.searchNumber,
    this.message,
    this.errorCode,
  });

  const InstaWalkSearchResult.success({
    required String requestId,
    DateTime? expiresAt,
    Duration? duration,
    int? searchNumber,
  }) : this(
          success: true,
          requestId: requestId,
          expiresAt: expiresAt,
          duration: duration,
          searchNumber: searchNumber,
        );

  const InstaWalkSearchResult.failure({
    required String message,
    String? errorCode,
  }) : this(
          success: false,
          message: message,
          errorCode: errorCode,
        );
}


// ==================================================================
// ACCEPTED DATA
// ==================================================================

class InstaWalkAcceptedData {
  final String requestId;
  final String businessId;
  final String ownerId;
  final String ownerAuthUid;
  final String ownerName;
  final String walkerUid;
  final String walkerId;
  final String walkerName;
  final DateTime? acceptedAt;
  final Map<String, dynamic> rawData;

  const InstaWalkAcceptedData({
    required this.requestId,
    required this.businessId,
    required this.ownerId,
    required this.ownerAuthUid,
    required this.ownerName,
    required this.walkerUid,
    required this.walkerId,
    required this.walkerName,
    required this.acceptedAt,
    required this.rawData,
  });

  factory InstaWalkAcceptedData.fromMap(
    Map<String, dynamic> data,
  ) {
    DateTime? acceptedAt;

    final dynamic acceptedValue =
        data['acceptedAt'];

    if (acceptedValue is Timestamp) {
      acceptedAt = acceptedValue.toDate();
    } else if (acceptedValue is DateTime) {
      acceptedAt = acceptedValue;
    }


    final String requestId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';


    String walkerUid =
        data['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (walkerUid.isEmpty) {
      walkerUid =
          data['acceptedBy']
                  ?.toString()
                  .trim() ??
              '';
    }


    String businessId =
        data['businessId']
                ?.toString()
                .trim() ??
            '';

    if (businessId.isEmpty) {
      businessId =
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '';
    }


    final String ownerId =
        data['ownerId']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? data['ownerId']
                .toString()
                .trim()
            : businessId;


    final String ownerAuthUid =
        data['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';


    final String rawOwnerName =
        data['ownerName']
                ?.toString()
                .trim() ??
            '';

    final String ownerName =
        rawOwnerName.isEmpty
            ? 'Dog Owner'
            : rawOwnerName;


    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';


    final String rawWalkerName =
        data['walkerName']
                ?.toString()
                .trim() ??
            '';

    final String walkerName =
        rawWalkerName.isEmpty
            ? 'Walker'
            : rawWalkerName;


    return InstaWalkAcceptedData(
      requestId: requestId,
      businessId: businessId,
      ownerId: ownerId,
      ownerAuthUid: ownerAuthUid,
      ownerName: ownerName,
      walkerUid: walkerUid,
      walkerId: walkerId,
      walkerName: walkerName,
      acceptedAt: acceptedAt,
      rawData: Map<String, dynamic>.from(data),
    );
  }

  bool get hasWalker =>
      walkerId.isNotEmpty ||
      walkerUid.isNotEmpty;
}


// ==================================================================
// REQUEST STATUS
// ==================================================================

enum InstaWalkRequestStatus {
  searching,
  accepted,
  expired,
  cancelled,
  notFound,
  unknown,
  error,
}


// ==================================================================
// REQUEST STATE
// ==================================================================

class InstaWalkRequestState {
  final InstaWalkRequestStatus status;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const InstaWalkRequestState({
    required this.status,
    this.data,
    this.errorMessage,
  });


  bool get isSearching =>
      status == InstaWalkRequestStatus.searching;


  bool get isAccepted =>
      status == InstaWalkRequestStatus.accepted;


  bool get isExpired =>
      status == InstaWalkRequestStatus.expired;


  bool get isCancelled =>
      status == InstaWalkRequestStatus.cancelled;


  String? get requestId {
    final String value =
        data?['requestId']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty ? null : value;
  }


  String? get businessId {
    String value =
        data?['businessId']
                ?.toString()
                .trim() ??
            '';

    if (value.isEmpty) {
      value =
          data?['ownerId']
                  ?.toString()
                  .trim() ??
              '';
    }

    return value.isEmpty ? null : value;
  }


  String? get ownerId => businessId;


  String? get ownerAuthUid {
    final String value =
        data?['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty ? null : value;
  }


  DateTime? get expiresAt {
    final dynamic value =
        data?['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }


  int? get searchNumber {
    final dynamic value =
        data?['searchNumber'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }


  String get statusText {
    switch (status) {
      case InstaWalkRequestStatus.searching:
        return 'Searching';

      case InstaWalkRequestStatus.accepted:
        return 'Accepted';

      case InstaWalkRequestStatus.expired:
        return 'Expired';

      case InstaWalkRequestStatus.cancelled:
        return 'Cancelled';

      case InstaWalkRequestStatus.notFound:
        return 'Not Found';

      case InstaWalkRequestStatus.unknown:
        return 'Unknown';

      case InstaWalkRequestStatus.error:
        return 'Error';
    }
  }
}
