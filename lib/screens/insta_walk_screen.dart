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

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF243746),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Insta Walk',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

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
            // Navigation is handled ONLY here.
            //
            // InstaWalkContainer:
            //   Firestore accepted
            //        ↓
            //   stop radar
            //        ↓
            //   stop searching
            //        ↓
            //   onAccepted
            //
            // This screen:
            //   onAccepted
            //        ↓
            //   WalkerAcceptScreen
            //
            // ==================================================

            onAccepted: (accepted) {
              final String requestId =
                  accepted.requestId.trim();

              debugPrint('');
              debugPrint(
                '==============================================',
              );
              debugPrint(
                '🔥 INSTA WALK SCREEN RECEIVED ACCEPTED',
              );
              debugPrint(
                'requestId = $requestId',
              );
              debugPrint(
                '==============================================',
              );

              if (requestId.isEmpty) {
                debugPrint(
                  '❌ Navigation cancelled: requestId is empty.',
                );
                return;
              }

              // ----------------------------------------------
              // WAIT UNTIL CURRENT FRAME IS COMPLETE
              // ----------------------------------------------

              WidgetsBinding.instance.addPostFrameCallback(
                (_) {
                  if (!context.mounted) {
                    debugPrint(
                      '❌ Navigation cancelled: screen unmounted.',
                    );
                    return;
                  }

                  debugPrint(
                    '🚀 Opening WalkerAcceptScreen...',
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WalkerAcceptScreen(
                        requestId: requestId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
