import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// INSTA WALK ACCEPTED DATA
// ============================================================

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
      acceptedAt =
          acceptedValue.toDate();
    } 
    else if (acceptedValue is DateTime) {
      acceptedAt = acceptedValue;
    }



    // ========================================================
    // REQUEST ID
    // ========================================================

    final String requestId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';



    // ========================================================
    // WALKER UID
    // ========================================================

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



    // ========================================================
    // BUSINESS ID
    // ========================================================

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



    // ========================================================
    // OWNER ID
    // ========================================================

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



    // ========================================================
    // OWNER AUTH UID
    // ========================================================

    final String ownerAuthUid =
        data['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';



    // ========================================================
    // OWNER NAME
    // ========================================================

    final String rawOwnerName =
        data['ownerName']
                ?.toString()
                .trim() ??
            '';


    final String ownerName =
        rawOwnerName.isEmpty
            ? 'Dog Owner'
            : rawOwnerName;



    // ========================================================
    // WALKER ID
    // ========================================================

    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';



    // ========================================================
    // WALKER NAME
    // ========================================================

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

      rawData:
          Map<String, dynamic>.from(data),
    );
  }



  // ==========================================================
  // HAS WALKER
  // ==========================================================

  bool get hasWalker =>
      walkerId.isNotEmpty ||
      walkerUid.isNotEmpty;
}
