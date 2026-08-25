import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'insta_walk_accepted_data.dart';
import 'insta_walk_request_state.dart';
import 'insta_walk_search_result.dart';

import 'insta_walk_firestore_helper.dart';
import 'insta_walk_status_helper.dart';


class InstaWalkSearchService {


  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) :
    _firestore =
        firestore ?? FirebaseFirestore.instance,

    _auth =
        auth ?? FirebaseAuth.instance,

    _helper =
        InstaWalkFirestoreHelper(
          firestore:
              firestore ?? FirebaseFirestore.instance,
        );



  final FirebaseFirestore _firestore;

  final FirebaseAuth _auth;


  final InstaWalkFirestoreHelper _helper;



  static const String walkRequestsCollection =
      'walk_requests';



  StreamSubscription<
      DocumentSnapshot<Map<String,dynamic>>>?
      _requestSubscription;


  String? _activeRequestId;



  String? get activeRequestId =>
      _activeRequestId;


  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.isNotEmpty;


  User? get currentUser =>
      _auth.currentUser;



  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<InstaWalkSearchResult> startSearch({

    required String ownerId,

    required String ownerName,

    required String address,

    required GeoPoint ownerLocation,

  }) async {


    final User? user =
        _auth.currentUser;


    if(user == null){

      return const InstaWalkSearchResult.failure(
        message:'Please login first.',
        errorCode:'unauthenticated',
      );

    }



    final String cleanOwnerId =
        ownerId.trim();


    final String cleanOwnerName =
        ownerName.trim().isEmpty
        ? 'Dog Owner'
        : ownerName.trim();


    final String cleanAddress =
        address.trim();



    if(cleanOwnerId.isEmpty){

      return const InstaWalkSearchResult.failure(
        message:'Owner ID missing.',
        errorCode:'missing-owner-id',
      );

    }



    if(cleanAddress.isEmpty){

      return const InstaWalkSearchResult.failure(
        message:'Address missing.',
        errorCode:'missing-address',
      );

    }



    try{


      final DocumentReference<
          Map<String,dynamic>> ref =

          await _helper.createRequest(

            data:{


              'status':
                  'searching',


              'searchType':
                  'insta_walk',


              'senderRole':
                  'owner',



              'senderUid':
                  user.uid,


              'ownerAuthUid':
                  user.uid,



              'ownerId':
                  cleanOwnerId,


              'businessId':
                  cleanOwnerId,


              'ownerName':
                  cleanOwnerName,


              'address':
                  cleanAddress,



              'ownerLocation':
                  ownerLocation,


              'ownerLocationType':
                  'search_snapshot',



              'walkerUid':
                  null,


              'walkerId':
                  null,


              'walkerName':
                  null,



              'acceptedBy':
                  null,


              'acceptedAt':
                  null,



              'createdAt':
                  FieldValue.serverTimestamp(),

            },

          );



      _activeRequestId =
          ref.id;



      return InstaWalkSearchResult.success(
        requestId:
            ref.id,
      );


    }
    on FirebaseException catch(e){


      return InstaWalkSearchResult.failure(

        message:
            e.message ??
            'Firestore error',

        errorCode:
            e.code,

      );


    }
    catch(e){


      return const InstaWalkSearchResult.failure(

        message:
            'Unable to start search.',

      );

    }

  }



  // ==========================================================
  // NEXT FUNCTIONS WILL COME HERE
  // listenForRequest()
  // getRequestState()
  // cancelSearch()
  // clearActiveRequest()
  // ==========================================================


}
