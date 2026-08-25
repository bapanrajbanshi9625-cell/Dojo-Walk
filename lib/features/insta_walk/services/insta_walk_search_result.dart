// ============================================================
// INSTA WALK SEARCH RESULT
// ============================================================

class InstaWalkSearchResult {
  final bool success;

  final String? requestId;

  // Compatibility fields
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
