import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/insta_walk_accepted_data.dart';
import '../models/insta_walk_request_state.dart';
import '../models/insta_walk_search_result.dart';

import 'insta_walk_firestore_helper.dart';
import 'insta_walk_status_helper.dart';


// ============================================================
// INSTA WALK SEARCH SERVICE
// ============================================================

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
                  firestore ??
                  FirebaseFirestore.instance,
            );



  final FirebaseFirestore _firestore;

  final FirebaseAuth _auth;

  final InstaWalkFirestoreHelper _helper;



  // ==========================================================
  // COLLECTION
  // ==========================================================

  static const String walkRequestsCollection =
      'walk_requests';



  // ==========================================================
  // STATE
  // ==========================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _subscription;


  String? _activeRequestId;



  String? get activeRequestId =>
      _activeRequestId;



  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.isNotEmpty;



  User? get currentUser =>
      _auth.currentUser;



  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<void> dispose() async {

    await _subscription?.cancel();

    _subscription = null;

    _activeRequestId = null;
  }



  // ==========================================================
  // START SEARCH
  //
  // NOTE:
  // Full create logic next part में आएगा.
  //
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


    // आगे create request वाला code Step 7 में आएगा


    return const InstaWalkSearchResult.failure(
      message:
          'Start search logic pending.',
    );
  }

}
