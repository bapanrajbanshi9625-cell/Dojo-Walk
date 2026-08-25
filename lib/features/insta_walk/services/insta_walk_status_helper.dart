// ============================================================
// INSTA WALK STATUS HELPER
// ============================================================

class InstaWalkStatusHelper {


  // ==========================================================
  // READ STATUS
  // ==========================================================

  static String statusFromData(
    Map<String, dynamic> data,
  ) {

    return data['status']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
  }



  // ==========================================================
  // SEARCHING
  // ==========================================================

  static bool isSearching(
    Map<String, dynamic> data,
  ) {

    return statusFromData(data) ==
        'searching';
  }



  // ==========================================================
  // ACCEPTED
  // ==========================================================

  static bool isAccepted(
    Map<String, dynamic> data,
  ) {

    return statusFromData(data) ==
        'accepted';
  }



  // ==========================================================
  // EXPIRED
  // ==========================================================

  static bool isExpired(
    Map<String, dynamic> data,
  ) {

    return statusFromData(data) ==
        'expired';
  }



  // ==========================================================
  // CANCELLED
  // ==========================================================

  static bool isCancelled(
    Map<String, dynamic> data,
  ) {

    final String status =
        statusFromData(data);


    return status == 'cancelled' ||
        status == 'owner_cancelled' ||
        status == 'walker_cancelled';
  }



  // ==========================================================
  // ACTIVE REQUEST
  // ==========================================================

  static bool isActive(
    Map<String, dynamic> data,
  ) {

    return isSearching(data) ||
        isAccepted(data);
  }
}
