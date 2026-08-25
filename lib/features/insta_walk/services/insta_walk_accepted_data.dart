import 'package:cloud_firestore/cloud_firestore.dart';


class InstaWalkAcceptedData {

  final String requestId;

  final String ownerId;

  final String ownerName;

  final String address;

  final String walkerId;

  final String walkerUid;

  final String walkerName;

  final String? walkerPhone;

  final GeoPoint? ownerLocation;

  final DateTime? acceptedAt;



  const InstaWalkAcceptedData({

    required this.requestId,

    required this.ownerId,

    required this.ownerName,

    required this.address,

    required this.walkerId,

    required this.walkerUid,

    required this.walkerName,

    this.walkerPhone,

    this.ownerLocation,

    this.acceptedAt,

  });



  factory InstaWalkAcceptedData.fromMap(
    Map<String,dynamic> map,
  ){

    return InstaWalkAcceptedData(

      requestId:
          map['requestId']
              ?.toString() ??
              '',


      ownerId:
          map['ownerId']
              ?.toString() ??
              '',


      ownerName:
          map['ownerName']
              ?.toString() ??
              'Dog Owner',


      address:
          map['address']
              ?.toString() ??
              '',


      walkerId:
          map['walkerId']
              ?.toString() ??
              '',


      walkerUid:
          map['walkerUid']
              ?.toString() ??
              '',


      walkerName:
          map['walkerName']
              ?.toString() ??
              'Walker',


      walkerPhone:
          map['walkerPhone']
              ?.toString(),


      ownerLocation:
          map['ownerLocation']
              is GeoPoint
          ? map['ownerLocation']
          : null,


      acceptedAt:
          _parseDate(
            map['acceptedAt'],
          ),

    );

  }



  static DateTime? _parseDate(
    dynamic value,
  ){

    if(value == null){
      return null;
    }


    if(value is Timestamp){
      return value.toDate();
    }


    if(value is DateTime){
      return value;
    }


    return null;

  }

}
