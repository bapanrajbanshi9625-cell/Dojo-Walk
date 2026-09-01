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
            // ACCEPTED
            // ==================================================
            //
            // Container detects Firestore:
            //
            // status = accepted
            //
            // Then:
            //
            // _walkerAccepted()
            //       ↓
            // onAccepted()
            //       ↓
            // THIS SCREEN NAVIGATES
            //
            // ==================================================

            onAccepted: (accepted) {
              debugPrint('');
              debugPrint(
                '==============================================',
              );
              debugPrint(
                '🔥 INSTA WALK SCREEN RECEIVED ACCEPTED',
              );
              debugPrint(
                '==============================================',
              );

              final String requestId =
                  accepted.requestId.trim();

              debugPrint(
                'requestId = $requestId',
              );

              // ----------------------------------------------
              // REQUEST ID CHECK
              // ----------------------------------------------

              if (requestId.isEmpty) {
                debugPrint(
                  '❌ Navigation cancelled: requestId empty.',
                );
                return;
              }

              // ----------------------------------------------
              // NAVIGATE AFTER CURRENT FRAME
              // ----------------------------------------------

              WidgetsBinding.instance.addPostFrameCallback(
                (_) {
                  if (!context.mounted) {
                    debugPrint(
                      '❌ Navigation cancelled: context unmounted.',
                    );
                    return;
                  }

                  debugPrint(
                    '🚀🚀🚀 PUSHING WalkerAcceptScreen',
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) {
                        return WalkerAcceptScreen(
                          requestId: requestId,
                        );
                      },
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
