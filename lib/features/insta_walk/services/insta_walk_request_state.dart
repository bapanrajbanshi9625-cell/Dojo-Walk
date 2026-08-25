import 'package:cloud_firestore/cloud_firestore.dart';

enum InstaWalkRequestStatus {
  searching,
  accepted,
  cancelled,
  expired,
  notFound,
}


class InstaWalkRequestState {

  final String status;

  final Map<String, dynamic>? data;


  const InstaWalkRequestState({
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



  static const InstaWalkRequestState notFound =
      InstaWalkRequestState(
        status: 'not_found',
      );



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



  factory InstaWalkRequestState.fromDocument(
    DocumentSnapshot<Map<String,dynamic>> doc,
  ){

    if(!doc.exists){

      return notFound;

    }


    final Map<String,dynamic> map =
        doc.data() ?? <String,dynamic>{};


    return InstaWalkRequestState(
      status:
          map['status']?.toString() ??
          'not_found',

      data:
          map,
    );

  }

}
