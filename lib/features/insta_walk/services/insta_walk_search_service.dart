import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'insta_walk_accepted_data.dart';
import 'insta_walk_request_state.dart';
import 'insta_walk_search_result.dart';

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



  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore;

  final FirebaseAuth _auth;



  // ==========================================================
  // HELPER
  // ==========================================================

  final InstaWalkFirestoreHelper _helper;



  // ==========================================================
  // COLLECTION
  // ==========================================================

  static const String walkRequestsCollection =
      'walk_requests';



  // ==========================================================
  // INTERNAL STATE
  // ==========================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;


  String? _activeRequestId;



  // ==========================================================
  // GETTERS
  // ==========================================================

  String? get activeRequestId =>
      _activeRequestId;


  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;


  User? get currentUser =>
      _auth.currentUser;
