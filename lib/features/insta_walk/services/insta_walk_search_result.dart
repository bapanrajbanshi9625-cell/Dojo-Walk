// ============================================================
// INSTA WALK SEARCH RESULT
// ============================================================

class InstaWalkSearchResult {
  final bool success;

  // ==========================================================
  // INTERNAL FIRESTORE REQUEST ID
  // ==========================================================

  final String? requestId;

  // ==========================================================
  // PROFESSIONAL DOJO WALK ID
  //
  // Example:
  // DW-000001
  // DW-000002
  // ==========================================================

  final String? walkId;

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
    this.walkId,

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

    String? walkId,

    DateTime? expiresAt,
    Duration? duration,
    int? searchNumber,
  }) : this(
          success: true,

          requestId: requestId,
          walkId: walkId,

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
