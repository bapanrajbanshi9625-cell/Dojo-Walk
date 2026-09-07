class AcceptLiveStripData {
  const AcceptLiveStripData({
    required this.requestId,
    this.walkId,
    this.sessionStatus = '',
    this.hasAcceptedRequest = false,
    this.isLive = false,
  });

  final String? requestId;
  final String? walkId;
  final String sessionStatus;
  final bool hasAcceptedRequest;
  final bool isLive;

  bool get isVisible {
    if (!hasAcceptedRequest) {
      return false;
    }

    if (requestId == null || requestId!.trim().isEmpty) {
      return false;
    }

    if (isCompleted) {
      return false;
    }

    return true;
  }

  bool get isCompleted {
    final String status =
        sessionStatus.trim().toLowerCase();

    return status == 'completed' ||
        status == 'complete' ||
        status == 'finished' ||
        status == 'closed' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'expired' ||
        status == 'ended';
  }

  AcceptLiveStripData copyWith({
    String? requestId,
    String? walkId,
    String? sessionStatus,
    bool? hasAcceptedRequest,
    bool? isLive,
  }) {
    return AcceptLiveStripData(
      requestId: requestId ?? this.requestId,
      walkId: walkId ?? this.walkId,
      sessionStatus:
          sessionStatus ?? this.sessionStatus,
      hasAcceptedRequest:
          hasAcceptedRequest ?? this.hasAcceptedRequest,
      isLive: isLive ?? this.isLive,
    );
  }

  static const AcceptLiveStripData empty =
      AcceptLiveStripData(
    requestId: null,
    walkId: null,
    sessionStatus: '',
    hasAcceptedRequest: false,
    isLive: false,
  );
}
