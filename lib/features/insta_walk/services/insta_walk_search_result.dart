// ============================================================
// INSTA WALK SEARCH RESULT
// ============================================================

class InstaWalkSearchResult {
  final bool success;

  // ==========================================================
  // SINGLE DOJO WALK / REQUEST ID
  //
  // Example:
  // DW000001
  // DW000002
  //
  // यही ID:
  // walk_request/{id}
  // liveWalkSessions/{id}
  // walk_history/{id}
  // ==========================================================

  final String? requestId;

  // ==========================================================
  // COMPATIBILITY FIELDS
  // ==========================================================

  final DateTime? expiresAt;
  final Duration? duration;
  final int? searchNumber;

  // ==========================================================
  // RESULT MESSAGE
  // ==========================================================

  final String? message;
  final String? errorCode;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.duration,
    this.searchNumber,
    this.message,
    this.errorCode,
  });

  // ==========================================================
  // SUCCESS
  // ==========================================================

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

  // ==========================================================
  // FAILURE
  // ==========================================================

  const InstaWalkSearchResult.failure({
    required String message,
    String? errorCode,
  }) : this(
          success: false,
          message: message,
          errorCode: errorCode,
        );
}
