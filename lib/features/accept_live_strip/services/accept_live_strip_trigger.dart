import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcceptLiveStripTrigger {
  AcceptLiveStripTrigger({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  final StreamController<bool> _triggerController =
      StreamController<bool>.broadcast();

  Stream<bool> get triggerStream => _triggerController.stream;

  // ==========================================================
  // START CHECK
  // ==========================================================

  void start() {
    stop();

    final user = _auth.currentUser;

    if (user == null) {
      _emit(false);
      return;
    }

    _subscription = _firestore
        .collection('walk_requests')
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        _checkRequests(snapshot);
      },
      onError: (_) {
        _emit(false);
      },
    );
  }

  // ==========================================================
  // CHECK ACCEPTED / LIVE WALK
  // ==========================================================

  void _checkRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    bool shouldTrigger = false;

    for (final document in snapshot.docs) {
      final data = document.data();

      final status = data['status']?.toString().toLowerCase();

      if (status == 'accepted' || status == 'live') {
        shouldTrigger = true;
        break;
      }
    }

    _emit(shouldTrigger);
  }

  // ==========================================================
  // TRIGGER
  // ==========================================================

  void _emit(bool value) {
    if (!_triggerController.isClosed) {
      _triggerController.add(value);
    }
  }

  // ==========================================================
  // STOP
  // ==========================================================

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  void dispose() {
    stop();
    _triggerController.close();
  }
}
