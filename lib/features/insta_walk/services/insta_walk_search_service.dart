import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'insta_walk_search_result.dart';
import 'insta_walk_request_state.dart';
import 'insta_walk_firestore_helper.dart';


class InstaWalkSearchService {

  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
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


  static const double searchRadiusKm =
      3.5;


  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;


  String? _activeRequestId;


  String? get activeRequestId =>
      _activeRequestId;


  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;


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


    if (user == null) {

      return const InstaWalkSearchResult.failure(
        message:
            'Please login first.',
        errorCode:
            'unauthenticated',
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



    if (cleanOwnerId.isEmpty) {

      return const InstaWalkSearchResult.failure(
        message:
            'Owner ID missing.',
        errorCode:
            'missing-owner-id',
      );

    }



    if (cleanAddress.isEmpty) {

      return const InstaWalkSearchResult.failure(
        message:
            'Address missing.',
        errorCode:
            'missing-address',
      );

    }



    try {

      final DocumentReference<
          Map<String, dynamic>> ref =
          await _helper.createRequest(

        data: {


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


          'searchRadiusKm':
              searchRadiusKm,


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


    } on FirebaseException catch (e) {


      return InstaWalkSearchResult.failure(

        message:
            e.message ??
            'Firestore error',

        errorCode:
            e.code,

      );


    } catch (e) {


      return const InstaWalkSearchResult.failure(

        message:
            'Unable to start search.',

      );

    }

  }


    // ==========================================================
  // LISTEN FOR REQUEST
  // ==========================================================

  Stream<InstaWalkRequestState> listenForRequest(
    String requestId,
  ) {

    _requestSubscription?.cancel();


    return _firestore
        .collection(
          walkRequestsCollection,
        )
        .doc(requestId)
        .snapshots()
        .map(
          (snapshot) {

            if (!snapshot.exists) {

              return InstaWalkRequestState.notFound(
                requestId: requestId,
              );

            }


            return InstaWalkRequestState.fromMap(
              requestId,
              snapshot.data()
                  ?? <String, dynamic>{},
            );

          },
        );

  }



  // ==========================================================
  // GET REQUEST STATE
  // ==========================================================

  Future<InstaWalkRequestState> getRequestState(
    String requestId,
  ) async {

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc(requestId)
            .get();



    if (!snapshot.exists) {

      return InstaWalkRequestState.notFound(
        requestId: requestId,
      );

    }



    return InstaWalkRequestState.fromMap(
      requestId,
      snapshot.data()
          ?? <String, dynamic>{},
    );

  }



  // ==========================================================
  // FIND OWNER PROFILE
  //
  // FIRESTORE:
  // ownerProfiles/{uid}
  // ==========================================================
  
  Future<DocumentSnapshot<Map<String, dynamic>>?>
    findOwnerProfile() async {

  final User? user = _auth.currentUser;

  if (user == null) {
    return null;
  }

  try {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('ownerProfiles')
            .where(
              'authUid',
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  } on FirebaseException catch (e) {
    print(
      'findOwnerProfile Firebase error: '
      '${e.code} - ${e.message}',
    );
    rethrow;
  } catch (e) {
    print(
      'findOwnerProfile error: $e',
    );
    rethrow;
  }
  }
  
  // ==========================================================
  // FIND ACTIVE REQUEST
  // ==========================================================

  
  Future<InstaWalkRequestState?>
      findActiveRequest({
        required String ownerId,
      }) async {


    final User? user =
        _auth.currentUser;


    if (user == null) {

      return null;

    }



    final QuerySnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(
              walkRequestsCollection,
            )
            .where(
              'ownerAuthUid',
              isEqualTo:
                  user.uid,
            )
            .where(
              'status',
              isEqualTo:
                  'searching',
            )
            .limit(1)
            .get();



    if (snapshot.docs.isEmpty) {

      return null;

    }



    final QueryDocumentSnapshot<
        Map<String, dynamic>> doc =
        snapshot.docs.first;


    _activeRequestId =
        doc.id;



    return InstaWalkRequestState.fromMap(
      doc.id,
      doc.data(),
    );

  }



  // ==========================================================
  // CANCEL SEARCH
  // ==========================================================

  Future<bool> cancelSearch({
    required String requestId,
  }) async {

    try {

      await _firestore
          .collection(
            walkRequestsCollection,
          )
          .doc(requestId)
          .update({

            'status':
                'cancelled',

            'cancelledAt':
                FieldValue.serverTimestamp(),

          });



      if (_activeRequestId ==
          requestId) {

        _activeRequestId = null;

      }



      return true;


    } catch (e) {

      return false;

    }

  }



  // ==========================================================
  // DISPOSE
  // ==========================================================

  void dispose() {

    _requestSubscription?.cancel();

    _requestSubscription = null;

  }

}
