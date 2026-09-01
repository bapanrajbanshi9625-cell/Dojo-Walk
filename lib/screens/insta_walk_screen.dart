import 'package:flutter/material.dart';

import '../features/insta_walk/services/insta_walk_accepted_data.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/walker_accept/screens/walker_accept_screen.dart';

class InstaWalkScreen extends StatefulWidget {
  const InstaWalkScreen({
    super.key,
  });

  @override
  State<InstaWalkScreen> createState() =>
      _InstaWalkScreenState();
}

class _InstaWalkScreenState
    extends State<InstaWalkScreen> {
  bool _openingWalkerAcceptScreen = false;

  // ==========================================================
  // WALKER ACCEPTED
  // ==========================================================

  Future<void> _openWalkerAcceptScreen(
    InstaWalkAcceptedData accepted,
  ) async {
    // ========================================================
    // PREVENT DUPLICATE NAVIGATION
    // ========================================================

    if (_openingWalkerAcceptScreen) {
      debugPrint(
        'WalkerAcceptScreen navigation already running.',
      );
      return;
    }

    final String requestId =
        accepted.requestId.trim();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'INSTA WALK PARENT onAccepted FIRED',
    );

    debugPrint(
      'requestId=$requestId',
    );

    debugPrint(
      '==================================================',
    );

    // ========================================================
    // VALIDATE REQUEST ID
    // ========================================================

    if (requestId.isEmpty) {
      debugPrint(
        'Cannot open WalkerAcceptScreen: requestId is empty.',
      );
      return;
    }

    // ========================================================
    // SET NAVIGATION LOCK
    // ========================================================

    _openingWalkerAcceptScreen = true;

    if (!mounted) {
      return;
    }

    // ========================================================
    // OPEN WALKER ACCEPT SCREEN
    // ========================================================

    debugPrint(
      'OPENING WalkerAcceptScreen NOW',
    );

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            debugPrint(
              'WalkerAcceptScreen BUILDING',
            );

            return WalkerAcceptScreen(
              requestId: requestId,
            );
          },
        ),
      );

      debugPrint(
        'WalkerAcceptScreen CLOSED',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WalkerAcceptScreen navigation ERROR: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _openingWalkerAcceptScreen = false;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F8),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF243746),
        foregroundColor:
            Colors.white,
        elevation: 0,
        title: const Text(
          'Insta Walk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: InstaWalkContainer(
          fullScreen: true,

          // ==================================================
          // ACCEPTED
          // ==================================================

          onAccepted:
              _openWalkerAcceptScreen,
        ),
      ),
    );
  }
}
