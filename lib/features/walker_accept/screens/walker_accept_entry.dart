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
    final User? user = _auth.currentUser;

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
      onError: (Object error) {
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
      final Map<String, dynamic> data =
          doc.data();

      final String status =
          _readStatus(data['status']);

      // --------------------------------------------------------
      // ONLY ACCEPTED REQUESTS CAN OPEN ACCEPT SCREEN
      // --------------------------------------------------------

      if (status != 'accepted') {
        continue;
      }

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // If this request already reached the owner,
      // it is an old/in-progress request and must NOT
      // reopen Accept Screen.
      //
      // This prevents:
      //
      // accepted + reached:true
      //        ↓
      // Accept Screen
      //        ↓
      // Live Walk
      //
      // from happening again.
      // --------------------------------------------------------

      if (data['reached'] == true) {
        debugPrint(
          'WalkerAcceptEntry → skipping already reached request: ${doc.id}',
        );

        continue;
      }

      // --------------------------------------------------------
      // NEVER OPEN TERMINAL REQUESTS
      // --------------------------------------------------------

      if (_isTerminalStatus(status)) {
        debugPrint(
          'WalkerAcceptEntry → skipping terminal request: '
          '${doc.id}, status=$status',
        );

        continue;
      }

      // --------------------------------------------------------
      // FIND NEWEST ACCEPTED REQUEST
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

    // ----------------------------------------------------------
    // NO VALID ACCEPTED REQUEST
    // ----------------------------------------------------------

    if (acceptedRequest == null) {
      return;
    }

    final String requestId =
        acceptedRequest.id.trim();

    if (requestId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // SAME REQUEST MUST NOT AUTO-OPEN AGAIN
    // ----------------------------------------------------------

    if (_openedRequestId == requestId) {
      return;
    }

    _openWalkerAcceptScreen(requestId);
  }

  // ============================================================
  // TERMINAL STATUS
  // ============================================================

  bool _isTerminalStatus(
    String status,
  ) {
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
  // OPEN SCREEN
  // ============================================================

  Future<void> _openWalkerAcceptScreen(
    String requestId,
  ) async {
    if (_opening) {
      return;
    }

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
          builder: (_) {
            return WalkerAcceptScreen(
              requestId: cleanRequestId,
            );
          },
        ),
      );
    } catch (
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint(
        'WalkerAcceptEntry navigation error: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
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
    final DateTime? updatedAt =
        _toDate(
      data['updatedAt'],
    );

    if (updatedAt != null) {
      return updatedAt;
    }

    final DateTime? acceptedAt =
        _toDate(
      data['acceptedAt'],
    );

    if (acceptedAt != null) {
      return acceptedAt;
    }

    final DateTime? createdAt =
        _toDate(
      data['createdAt'],
    );

    if (createdAt != null) {
      return createdAt;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  // ============================================================
  // DATE
  // ============================================================

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
