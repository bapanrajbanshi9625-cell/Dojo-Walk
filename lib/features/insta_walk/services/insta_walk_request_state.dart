import 'package:cloud_firestore/cloud_firestore.dart';

enum InstaWalkRequestStatus {
  searching,
  accepted,
  cancelled,
  expired,
  notFound,
}


class InstaWalkRequestState {

  final String requestId;

  final String status;

  final Map<String, dynamic>? data;


  const InstaWalkRequestState({
    required this.requestId,
    required this.status,
    this.data,
  });



  bool get isAccepted =>
      status == 'accepted';



  bool get isCancelled =>
      status == 'cancelled';



  bool get isExpired =>
      status == 'expired';



  bool get isSearching =>
      status == 'searching';



  static InstaWalkRequestState notFound({
    String requestId = '',
  }) {
    return InstaWalkRequestState(
      requestId: requestId,
      status: 'not_found',
    );
  }



  InstaWalkRequestStatus get requestStatus {

    switch(status){

      case 'searching':
        return InstaWalkRequestStatus.searching;


      case 'accepted':
        return InstaWalkRequestStatus.accepted;


      case 'cancelled':
        return InstaWalkRequestStatus.cancelled;


      case 'expired':
        return InstaWalkRequestStatus.expired;


      default:
        return InstaWalkRequestStatus.notFound;

    }

  }



  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory InstaWalkRequestState.fromMap(
    String requestId,
    Map<String, dynamic> data,
  ) {

    return InstaWalkRequestState(
      requestId: requestId,

      status:
          data['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
          'not_found',

      data: data,
    );

  }



  // ==========================================================
  // FROM FIRESTORE DOCUMENT
  // ==========================================================

  factory InstaWalkRequestState.fromDocument(
    DocumentSnapshot<Map<String,dynamic>> doc,
  ){

    if(!doc.exists){

      return InstaWalkRequestState.notFound(
        requestId: doc.id,
      );

    }


    final Map<String,dynamic> map =
        doc.data() ??
        <String,dynamic>{};



    return InstaWalkRequestState(
      requestId: doc.id,

      status:
          map['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
          'not_found',

      data: map,
    );

  }

}
