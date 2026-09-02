// File location:
// lib/widgets/active_live_walk_strip.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/walker_accept/screens/walker_accept_screen.dart';

class ActiveLiveWalkStrip extends StatefulWidget {
  const ActiveLiveWalkStrip({
    super.key,
    required this.isWalker,
  });

  final bool isWalker;

  @override
  State<ActiveLiveWalkStrip> createState() =>
      _ActiveLiveWalkStripState();
}

class _ActiveLiveWalkStripState
    extends State<ActiveLiveWalkStrip> {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<
          QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  // ==========================================================
  // CORRECT COLLECTION
  // ==========================================================

  static const String collectionName =
      'walk_request';

  // ==========================================================
  // CURRENT REQUEST
  // ==========================================================

  String? _requestId;

  String _status = '';

  String _dogName = 'Dog';

  String _dogBreed = '';

  String _walkerName = 'Walker';

  bool _loading = true;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  static const Color slate =
      Color(0xFF475569);

  static const Color border =
      Color(0xFFE5E7EB);

  // ==========================================================
  // ACTIVE STATUSES
  // ==========================================================

  static const Set<String> _activeStatuses = {
    'accepted',
    'on_the_way',
    'reached',
    'walking',
    'in_progress',
    'started',
    'ongoing',
    'live',
  };

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _startListener();
  }

  // ==========================================================
  // LISTENER
  // ==========================================================

  void _startListener() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _requestId = null;
      });

      return;
    }

    final String uid =
        user.uid;

    // --------------------------------------------------------
    // OWNER
    // --------------------------------------------------------

    final String field =
        widget.isWalker
            ? 'walkerUid'
            : 'ownerAuthUid';

    debugPrint(
      'ActiveLiveWalkStrip listening: '
      '$collectionName '
      '$field = $uid',
    );

    _subscription = _firestore
        .collection(collectionName)
        .where(
          field,
          isEqualTo: uid,
        )
        .snapshots()
        .listen(
      _onSnapshot,
      onError: _onError,
    );
  }

  // ==========================================================
  // SNAPSHOT
  // ==========================================================

  void _onSnapshot(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    if (!mounted) {
      return;
    }

    QueryDocumentSnapshot<
        Map<String, dynamic>>?
    selectedDocument;

    DateTime? newestTime;

    // ========================================================
    // FIND NEWEST ACTIVE REQUEST
    // ========================================================

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          _normalizeStatus(
        data['status'],
      );

      debugPrint(
        'walk_request ${document.id} '
        'status=$status',
      );

      if (!_activeStatuses.contains(status)) {
        continue;
      }

      // ------------------------------------------------------
      // UPDATED AT
      // ------------------------------------------------------

      final DateTime? updatedAt =
          _readDate(
        data['updatedAt'],
      );

      // ------------------------------------------------------
      // ACCEPTED AT
      // ------------------------------------------------------

      final DateTime? acceptedAt =
          _readDate(
        data['acceptedAt'],
      );

      // ------------------------------------------------------
      // CREATED AT
      // ------------------------------------------------------

      final DateTime? createdAt =
          _readDate(
        data['createdAt'],
      );

      final DateTime? candidateTime =
          updatedAt ??
              acceptedAt ??
              createdAt;

      // ------------------------------------------------------
      // FIRST MATCH
      // ------------------------------------------------------

      if (selectedDocument == null) {
        selectedDocument = document;
        newestTime = candidateTime;
        continue;
      }

      // ------------------------------------------------------
      // NEWEST MATCH
      // ------------------------------------------------------

      if (candidateTime != null &&
          (newestTime == null ||
              candidateTime.isAfter(
                newestTime,
              ))) {
        selectedDocument = document;
        newestTime = candidateTime;
      }
    }

    // ========================================================
    // NO ACTIVE REQUEST
    // ========================================================

    if (selectedDocument == null) {
      setState(() {
        _loading = false;
        _requestId = null;
        _status = '';
        _dogName = 'Dog';
        _dogBreed = '';
        _walkerName = 'Walker';
      });

      return;
    }

    // ========================================================
    // DATA
    // ========================================================

    final Map<String, dynamic> data =
        selectedDocument.data();

    final String status =
        _normalizeStatus(
      data['status'],
    );

    // ========================================================
    // DOG NAME
    // ========================================================

    String dogName =
        _readString(
      data['dogName'],
    );

    if (dogName.isEmpty) {
      dogName =
          _readString(data['petName']);
    }

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    // ========================================================
    // DOG BREED
    // ========================================================

    final String dogBreed =
        _readString(
      data['dogBreed'],
    );

    // ========================================================
    // WALKER NAME
    // ========================================================

    String walkerName =
        _readString(
      data['walkerName'],
    );

    if (walkerName.isEmpty) {
      walkerName = 'Walker';
    }

    // ========================================================
    // UPDATE
    // ========================================================

    setState(() {
  _loading = false;

  // Firestore document ID = request ID
  _requestId =
      selectedDocument!.id;

  _status = status;

  _dogName = dogName;

  _dogBreed = dogBreed;

  _walkerName = walkerName;
});

  // ==========================================================
  // ERROR
  // ==========================================================

  void _onError(Object error) {
    debugPrint(
      'ActiveLiveWalkStrip error: $error',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _requestId = null;
      _status = '';
    });
  }

  // ==========================================================
  // LIVE
  // ==========================================================

  bool get _isLive {
    switch (_status) {
      case 'reached':
      case 'walking':
      case 'in_progress':
      case 'started':
      case 'ongoing':
      case 'live':
        return true;

      default:
        return false;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading ||
        _requestId == null) {
      return const SizedBox.shrink();
    }

    final Color statusColor =
        _isLive
            ? green
            : primary;

    final String title =
        _isLive
            ? 'LIVE WALK'
            : 'ACTIVE WALK';

    final String subtitle =
        widget.isWalker
            ? _buildWalkerSubtitle()
            : _buildOwnerSubtitle();

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _openLiveWalk,
        child: Container(
          width: double.infinity,
          height: 56,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color:
                    statusColor.withValues(
                  alpha: .18,
                ),
                width: .7,
              ),
              bottom: const BorderSide(
                color: border,
                width: .6,
              ),
            ),
          ),
          child: Row(
            children: [
              // =================================================
              // ICON
              // =================================================

              Container(
                width: 38,
                height: 38,
                decoration:
                    BoxDecoration(
                  color:
                      statusColor.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    11,
                  ),
                ),
                child: Icon(
                  Icons
                      .directions_walk_rounded,
                  color: statusColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // TEXT
              // =================================================

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(
                            color:
                                statusColor,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          title,
                          style:
                              TextStyle(
                            color:
                                statusColor,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing:
                                .7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: navy,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // ARROW
              // =================================================

              const Icon(
                Icons.chevron_right_rounded,
                color: slate,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // OWNER SUBTITLE
  // ==========================================================

  String _buildOwnerSubtitle() {
    if (_walkerName != 'Walker') {
      return '$_dogName • $_walkerName';
    }

    return _dogName;
  }

  // ==========================================================
  // WALKER SUBTITLE
  // ==========================================================

  String _buildWalkerSubtitle() {
    if (_dogBreed.isNotEmpty) {
      return '$_dogName • $_dogBreed';
    }

    return _dogName;
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  void _openLiveWalk() {
    final String? id =
        _requestId;

    if (id == null ||
        id.trim().isEmpty) {
      return;
    }

    final String requestId =
        id.trim();

    // --------------------------------------------------------
    // OWNER
    // --------------------------------------------------------

    if (!widget.isWalker) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              WalkerAcceptScreen(
            requestId: requestId,
          ),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // WALKER
    //
    // Keep existing Walker live screen.
    // --------------------------------------------------------

    debugPrint(
      'Walker ActiveLiveWalkStrip tapped: '
      'requestId=$requestId',
    );
  }

  // ==========================================================
  // NORMALIZE STATUS
  // ==========================================================

  String _normalizeStatus(
    dynamic value,
  ) {
    String status =
        _readString(value)
            .toLowerCase()
            .trim();

    status = status.replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    status = status.replaceAll(
      '-',
      '_',
    );

    while (status.contains('__')) {
      status = status.replaceAll(
        '__',
        '_',
      );
    }

    if (status == 'on_that_way') {
      return 'on_the_way';
    }

    if (status == 'ontheway') {
      return 'on_the_way';
    }

    if (status == 'on_way') {
      return 'on_the_way';
    }

    if (status == 'started_walk') {
      return 'started';
    }

    if (status == 'walk_started') {
      return 'started';
    }

    return status;
  }

  // ==========================================================
  // STRING
  // ==========================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // DATE
  // ==========================================================

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
