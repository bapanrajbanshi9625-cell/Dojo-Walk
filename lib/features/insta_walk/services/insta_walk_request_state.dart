import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// INSTA WALK REQUEST STATUS
// ============================================================

enum InstaWalkRequestStatus {
  searching,
  pending,
  accepted,
  active,
  completed,
  cancelled,
  expired,
  rejected,
  notFound,
}

// ============================================================
// INSTA WALK REQUEST STATE
// ============================================================

class InstaWalkRequestState {
  final String requestId;

  final String status;

  final Map<String, dynamic>? data;

  const InstaWalkRequestState({
    required this.requestId,
    required this.status,
    this.data,
  });

  // ==========================================================
  // STATUS HELPERS
  // ==========================================================

  bool get isSearching =>
      status == 'searching';

  bool get isPending =>
      status == 'pending';

  bool get isAccepted =>
      status == 'accepted';

  bool get isActive =>
      status == 'active';

  bool get isCompleted =>
      status == 'completed';

  bool get isCancelled =>
      status == 'cancelled' ||
      status == 'canceled';

  bool get isExpired =>
      status == 'expired';

  bool get isRejected =>
      status == 'rejected';

  bool get isNotFound =>
      status == 'not_found';

  // ==========================================================
  // WALKER DATA
  // ==========================================================

  String get walkerUid =>
      data?['walkerUid']?.toString().trim() ?? '';

  String get walkerId =>
      data?['walkerId']?.toString().trim() ?? '';

  String get walkerName =>
      data?['walkerName']?.toString().trim() ?? '';

  // ==========================================================
  // OWNER DATA
  // ==========================================================

  String get ownerId =>
      data?['ownerId']?.toString().trim() ?? '';

  String get ownerAuthUid =>
      data?['ownerAuthUid']?.toString().trim() ?? '';

  String get ownerName =>
      data?['ownerName']?.toString().trim() ?? '';

  // ==========================================================
  // DOG DATA
  // ==========================================================

  String get dogId =>
      data?['dogId']?.toString().trim() ?? '';

  String get dogName =>
      data?['dogName']?.toString().trim() ?? '';

  String get dogBreed =>
      data?['dogBreed']?.toString().trim() ?? '';

  String get dogPhoto =>
      data?['dogPhoto']?.toString().trim() ?? '';

  // ==========================================================
  // LOCATION DATA
  // ==========================================================

  String get address =>
      data?['address']?.toString().trim() ?? '';

  double? get latitude {
    final value = data?['latitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  double? get longitude {
    final value = data?['longitude'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  double? get searchRadiusKm {
    final value = data?['searchRadiusKm'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  // ==========================================================
  // SEARCH TYPE
  // ==========================================================

  String get searchType =>
      data?['searchType']?.toString().trim() ?? '';

  // ==========================================================
  // STATUS ENUM
  // ==========================================================

  InstaWalkRequestStatus get requestStatus {
    switch (status) {
      case 'searching':
        return InstaWalkRequestStatus.searching;

      case 'pending':
        return InstaWalkRequestStatus.pending;

      case 'accepted':
        return InstaWalkRequestStatus.accepted;

      case 'active':
        return InstaWalkRequestStatus.active;

      case 'completed':
        return InstaWalkRequestStatus.completed;

      case 'cancelled':
      case 'canceled':
        return InstaWalkRequestStatus.cancelled;

      case 'expired':
        return InstaWalkRequestStatus.expired;

      case 'rejected':
        return InstaWalkRequestStatus.rejected;

      default:
        return InstaWalkRequestStatus.notFound;
    }
  }

  // ==========================================================
  // NOT FOUND
  // ==========================================================

  static InstaWalkRequestState notFound({
    String requestId = '',
  }) {
    return InstaWalkRequestState(
      requestId: requestId,
      status: 'not_found',
      data: null,
    );
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory InstaWalkRequestState.fromMap(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final normalizedStatus =
        data['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'not_found';

    return InstaWalkRequestState(
      requestId: requestId,
      status: normalizedStatus,
      data: Map<String, dynamic>.from(data),
    );
  }

  // ==========================================================
  // FROM FIRESTORE DOCUMENT
  // ==========================================================

  factory InstaWalkRequestState.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) {
      return InstaWalkRequestState.notFound(
        requestId: doc.id,
      );
    }

    final map =
        doc.data() ??
        <String, dynamic>{};

    return InstaWalkRequestState.fromMap(
      doc.id,
      map,
    );
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  InstaWalkRequestState copyWith({
    String? requestId,
    String? status,
    Map<String, dynamic>? data,
  }) {
    return InstaWalkRequestState(
      requestId:
          requestId ?? this.requestId,
      status:
          status ?? this.status,
      data:
          data ?? this.data,
    );
  }

  // ==========================================================
  // DEBUG
  // ==========================================================

  @override
  String toString() {
    return 'InstaWalkRequestState('
        'requestId: $requestId, '
        'status: $status, '
        'walkerUid: $walkerUid, '
        'walkerId: $walkerId, '
        'ownerId: $ownerId'
        ')';
  }
}
