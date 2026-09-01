import 'package:flutter/material.dart';

import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/walker_accept/screens/walker_accept_screen.dart';

class InstaWalkScreen extends StatelessWidget {
  const InstaWalkScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF243746),
        foregroundColor: Colors.white,
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 30,
          ),
          child: InstaWalkContainer(
            fullScreen: true,

            // ==================================================
            // WALKER ACCEPTED
            // ==================================================
            //
            // Insta Walk Container detects:
            //
            // status = accepted
            //
            // Then this callback immediately opens:
            //
            // WalkerAcceptScreen
            //
            // Same Firestore request:
            //
            // walk_request/{requestId}
            //
            // ==================================================

            onAccepted: (accepted) {
              final String requestId =
                  accepted.requestId.trim();

              if (requestId.isEmpty) {
                debugPrint(
                  'Cannot open WalkerAcceptScreen: '
                  'requestId is empty.',
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WalkerAcceptScreen(
                    requestId: requestId,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
