// File location:
// lib/widgets/active_live_walk_strip.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/live_walk_screen.dart';

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
  // CURRENT WALK
  // ==========================================================

  String? _activeWalkId;

  String _status = '';

  String _dogName = 'Dog';

  String _dogBreed = '';

  String _walkerName = 'Walker';

  // ==========================================================
  // STATE
  // ==========================================================

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
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _startListener();
  }

  // ==========================================================
  // START LISTENER
  // ==========================================================

  void _startListener() {
    final User? user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _activeWalkId = null;
        });
      }

      return;
    }

    final String uid = user.uid;

    final String field =
        widget.isWalker
            ? 'walkerUid'
            : 'ownerId';

    _subscription = _firestore
        .collection('active_walk')
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
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!mounted) {
      return;
    }

    QueryDocumentSnapshot<
        Map<String, dynamic>>? currentDocument;

    DateTime? newestTime;

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          _normalizeStatus(data['status']);

      // ------------------------------------------------------
      // ONLY ACTIVE/LIVE WALK STATUSES
      // ------------------------------------------------------

      if (!_isVisibleStatus(status)) {
        continue;
      }

      final DateTime? createdAt =
          _readDate(data['createdAt']);

      final DateTime? startedAt =
          _readDate(data['startedAt']);

      final DateTime? candidateTime =
          startedAt ?? createdAt;

      if (currentDocument == null) {
        currentDocument = document;
        newestTime = candidateTime;
        continue;
      }

      if (candidateTime != null &&
          (newestTime == null ||
              candidateTime.isAfter(
                newestTime!,
              ))) {
        currentDocument = document;
        newestTime = candidateTime;
      }
    }

    // ========================================================
    // NO ACTIVE WALK
    // ========================================================

    if (currentDocument == null) {
      setState(() {
        _loading = false;
        _activeWalkId = null;
        _status = '';
      });

      return;
    }

    // ========================================================
    // READ CURRENT WALK
    // ========================================================

    final Map<String, dynamic> data =
        currentDocument.data();

    final String status =
        _normalizeStatus(data['status']);

    String dogName =
        _readString(data['dogName']);

    if (dogName.isEmpty) {
      dogName =
          _readString(data['petName']);
    }

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    String dogBreed =
        _readString(data['dogBreed']);

    if (dogBreed.isEmpty) {
      dogBreed =
          _readString(data['breed']);
    }

    String walkerName =
        _readString(data['walkerName']);

    if (walkerName.isEmpty) {
      walkerName = 'Walker';
    }

    setState(() {
      _loading = false;

      _activeWalkId =
          currentDocument!.id;

      _status = status;

      _dogName = dogName;

      _dogBreed = dogBreed;

      _walkerName = walkerName;
    });
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _onError(Object error) {
    debugPrint(
      'ActiveLiveWalkStrip Firestore error: $error',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _activeWalkId = null;
      _status = '';
    });
  }

  // ==========================================================
  // VISIBLE STATUS
  // ==========================================================

  bool _isVisibleStatus(
    String status,
  ) {
    return status == 'accepted' ||
        status == 'active' ||
        status == 'on_the_way' ||
        status == 'reached' ||
        status == 'walking' ||
        status == 'in_progress';
  }

  // ==========================================================
  // LIVE STATUS
  // ==========================================================

  bool get _isLive {
    return _status == 'reached' ||
        _status == 'walking' ||
        _status == 'in_progress';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (_loading || _activeWalkId == null) {
      return const SizedBox.shrink();
    }

    final Color statusColor =
        _isLive ? green : primary;

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
                    statusColor.withOpacity(.18),
                width: 0.7,
              ),
              bottom: BorderSide(
                color:
                    border,
                width: 0.6,
              ),
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      statusColor.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  _isLive
                      ? Icons
                          .directions_walk_rounded
                      : Icons
                          .directions_walk_rounded,
                  color: statusColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              // ==================================================
              // TEXT
              // ==================================================

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
                            color: statusColor,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          title,
                          style: TextStyle(
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

                    const SizedBox(height: 2),

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

              // ==================================================
              // ARROW
              // ==================================================

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
    if (_walkerName.isNotEmpty &&
        _walkerName != 'Walker') {
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
        _activeWalkId;

    if (id == null || id.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            LiveWalkScreen(
          activeWalkId: id,
          isWalker: widget.isWalker,
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS NORMALIZER
  // ==========================================================

  String _normalizeStatus(
    dynamic value,
  ) {
    String status =
        _readString(value).toLowerCase();

    status = status
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    while (status.contains('__')) {
      status =
          status.replaceAll(
        '__',
        '_',
      );
    }

    // --------------------------------------------------------
    // FIREBASE VARIATIONS
    // --------------------------------------------------------

    if (status == 'on_that_way') {
      return 'on_the_way';
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
      return DateTime.tryParse(value);
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
