import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'walker_accept_screen.dart';

class WalkerAcceptEntry extends StatefulWidget {
  const WalkerAcceptEntry({
    super.key,
  });

  @override
  State<WalkerAcceptEntry> createState() =>
      _WalkerAcceptEntryState();
}

class _WalkerAcceptEntryState
    extends State<WalkerAcceptEntry> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<
      QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  String? _openedRequestId;

  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // LISTENER
  // ============================================================

  void _startListening() {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    _subscription = _firestore
        .collection('walk_request')
        .where(
          'ownerAuthUid',
          isEqualTo: user.uid,
        )
        .snapshots()
        .listen(
      _handleRequests,
      onError: (error) {
        debugPrint(
          'WalkerAcceptEntry error: $error',
        );
      },
    );
  }

  // ============================================================
  // REQUEST CHECK
  // ============================================================

  void _handleRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (_opening) {
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>?
        acceptedRequest;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final status = _readStatus(
        data['status'],
      );

      if (status != 'accepted') {
        continue;
      }

      if (acceptedRequest == null ||
          _latestTime(data).isAfter(
            _latestTime(
              acceptedRequest.data(),
            ),
          )) {
        acceptedRequest = doc;
      }
    }

    if (acceptedRequest == null) {
      return;
    }

    final requestId = acceptedRequest.id;

    // ----------------------------------------------------------
    // Same accepted request must not auto-open repeatedly.
    // ----------------------------------------------------------

    if (_openedRequestId == requestId) {
      return;
    }

    _openWalkerAcceptScreen(requestId);
  }

  // ============================================================
  // OPEN SCREEN
  // ============================================================

  Future<void> _openWalkerAcceptScreen(
    String requestId,
  ) async {
    if (_opening) {
      return;
    }

    _opening = true;
    _openedRequestId = requestId;

    if (!mounted) {
      _opening = false;
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WalkerAcceptScreen(
            requestId: requestId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WalkerAcceptEntry navigation error: $e',
      );
      debugPrint('$stackTrace');
    } finally {
      _opening = false;
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _readStatus(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toLowerCase();
  }

  // ============================================================
  // LATEST TIME
  // ============================================================

  DateTime _latestTime(
    Map<String, dynamic> data,
  ) {
    final updatedAt = _toDate(
      data['updatedAt'],
    );

    if (updatedAt != null) {
      return updatedAt;
    }

    final acceptedAt = _toDate(
      data['acceptedAt'],
    );

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final createdAt = _toDate(
      data['createdAt'],
    );

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _toDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // ENTRY HAS NO UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return const SizedBox.shrink();
  }
}
