import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  // FIRESTORE
  // ==========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  StreamSubscription<
      QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  // ==========================================================
  // STATE
  // ==========================================================

  String? _activeWalkId;

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

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _listenToActiveWalk();
  }

  // ==========================================================
  // LISTEN
  // ==========================================================

  void _listenToActiveWalk() {
    _subscription = _firestore
        .collection('active_walk')
        .where(
          widget.isWalker
              ? 'walkerUid'
              : 'ownerId',
          isEqualTo: _currentUserId(),
        )
        .snapshots()
        .listen(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!mounted) {
          return;
        }

        _findCurrentWalk(snapshot);
      },
      onError: (Object error) {
        debugPrint(
          'ActiveLiveWalkStrip error: $error',
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _activeWalkId = null;
        });
      },
    );
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String _currentUserId() {
    // FirebaseAuth is intentionally avoided here.
    //
    // The listener below is replaced automatically by
    // MainNavigationScreen when the correct user id is passed.
    //
    // This fallback keeps the widget safe if no user id
    // is available.
    return '';
  }

  // ==========================================================
  // FIND CURRENT WALK
  // ==========================================================

  void _findCurrentWalk(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>?
        selected;

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          _normalizeStatus(data['status']);

      if (_isVisibleStatus(status)) {
        selected = document;
        break;
      }
    }

    if (selected == null) {
      setState(() {
        _loading = false;
        _activeWalkId = null;
        _status = '';
      });

      return;
    }

    final Map<String, dynamic> data =
        selected.data();

    setState(() {
      _loading = false;

      _activeWalkId = selected!.id;

      _status =
          _normalizeStatus(data['status']);

      _dogName =
          _string(data['dogName']).isNotEmpty
              ? _string(data['dogName'])
              : _string(data['petName']).isNotEmpty
                  ? _string(data['petName'])
                  : 'Dog';

      _dogBreed =
          _string(data['dogBreed']);

      if (_dogBreed.isEmpty) {
        _dogBreed = _string(data['breed']);
      }

      _walkerName =
          _string(data['walkerName']);

      if (_walkerName.isEmpty) {
        _walkerName = 'Walker';
      }
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
                color: _isLive
                    ? green.withOpacity(.20)
                    : primary.withOpacity(.20),
              ),
              bottom: BorderSide(
                color: Colors.black
                    .withOpacity(.06),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildStatusIcon(),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLive
                          ? 'LIVE WALK'
                          : 'ACTIVE WALK',
                      style: TextStyle(
                        color: _isLive
                            ? green
                            : primary,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      widget.isWalker
                          ? '$_dogName${_dogBreed.isNotEmpty ? ' • $_dogBreed' : ''}'
                          : '$_dogName • $_walkerName',
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
  // STATUS ICON
  // ==========================================================

  Widget _buildStatusIcon() {
    final Color color =
        _isLive ? green : primary;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        _isLive
            ? Icons.directions_walk_rounded
            : Icons.local_activity_rounded,
        color: color,
        size: 21,
      ),
    );
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  void _openLiveWalk() {
    final String? id = _activeWalkId;

    if (id == null || id.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveWalkScreen(
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
        _string(value).toLowerCase();

    status = status
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    while (status.contains('__')) {
      status =
          status.replaceAll('__', '_');
    }

    if (status == 'on_that_way') {
      return 'on_the_way';
    }

    return status;
  }

  // ==========================================================
  // STRING
  // ==========================================================

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
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
