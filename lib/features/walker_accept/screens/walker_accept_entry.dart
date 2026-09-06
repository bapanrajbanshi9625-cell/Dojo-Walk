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
  // START FIRESTORE LISTENER
  // ============================================================

  void _startListening() {
    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        'WalkerAcceptEntry → no logged-in user.',
      );
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
      onError: (Object error) {
        debugPrint(
          'WalkerAcceptEntry Firestore error: $error',
        );
      },
    );
  }

  // ============================================================
  // HANDLE REQUESTS
  // ============================================================

  void _handleRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (_opening) return;

    QueryDocumentSnapshot<Map<String, dynamic>>?
        acceptedRequest;

    for (final doc in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();

      final String status =
          _readStatus(data['status']);

      // --------------------------------------------------------
      // ONLY ACCEPTED REQUESTS CAN OPEN ACCEPT SCREEN
      // --------------------------------------------------------

      if (status != 'accepted') {
        continue;
      }

      // --------------------------------------------------------
      // DO NOT REOPEN A REQUEST THAT HAS ALREADY REACHED
      // --------------------------------------------------------

      final dynamic reachedValue = data['reached'];

      if (reachedValue == true) {
        debugPrint(
          'WalkerAcceptEntry → skipping already reached '
          'request: ${doc.id}',
        );
        continue;
      }

      // --------------------------------------------------------
      // EXTRA TERMINAL STATUS SAFETY
      // --------------------------------------------------------

      if (_isTerminalStatus(status)) {
        debugPrint(
          'WalkerAcceptEntry → skipping terminal request: '
          '${doc.id}, status=$status',
        );
        continue;
      }

      // --------------------------------------------------------
      // FIND THE NEWEST ACCEPTED REQUEST
      // --------------------------------------------------------

      if (acceptedRequest == null ||
          _latestTime(data).isAfter(
            _latestTime(
              acceptedRequest.data(),
            ),
          )) {
        acceptedRequest = doc;
      }
    }

    // No valid accepted request.
    if (acceptedRequest == null) {
      return;
    }

    final String requestId =
        acceptedRequest.id.trim();

    if (requestId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // DON'T OPEN THE SAME REQUEST AGAIN
    // ----------------------------------------------------------

    if (_openedRequestId == requestId) {
      return;
    }

    _openWalkerAcceptScreen(requestId);
  }

  // ============================================================
  // OPEN WALKER ACCEPT SCREEN
  // ============================================================

  Future<void> _openWalkerAcceptScreen(
    String requestId,
  ) async {
    if (_opening) return;

    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return;
    }

    _opening = true;
    _openedRequestId = cleanRequestId;

    if (!mounted) {
      _opening = false;
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalkerAcceptScreen(
            requestId: cleanRequestId,
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WalkerAcceptEntry navigation error: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _opening = false;
    }
  }

  // ============================================================
  // READ STATUS
  // ============================================================

  String _readStatus(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toLowerCase();
  }

  // ============================================================
  // TERMINAL STATUS
  // ============================================================

  bool _isTerminalStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'completed':
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'expired':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // GET LATEST REQUEST TIME
  // ============================================================

  DateTime _latestTime(
    Map<String, dynamic> data,
  ) {
    final DateTime? updatedAt =
        _toDate(data['updatedAt']);

    if (updatedAt != null) {
      return updatedAt;
    }

    final DateTime? acceptedAt =
        _toDate(data['acceptedAt']);

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final DateTime? createdAt =
        _toDate(data['createdAt']);

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ============================================================
  // FIRESTORE TIMESTAMP → DATETIME
  // ============================================================

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ============================================================
  // INVISIBLE ENTRY WIDGET
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
