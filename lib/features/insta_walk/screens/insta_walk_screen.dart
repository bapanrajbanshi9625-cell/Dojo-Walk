import 'package:flutter/material.dart';

import '../widgets/insta_walk_container.dart';

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
            // Firestore:
            //
            // searching
            //     ↓
            // accepted
            //
            // InstaWalkContainer detects accepted status
            // and sends the accepted request here.
            //
            // IMPORTANT:
            // This screen belongs to OWNER.
            //
            // ==================================================

            onAccepted: (accepted) {
              debugPrint('');
              debugPrint(
                '==============================================',
              );
              debugPrint(
                '🔥 OWNER INSTA WALK: ACCEPTED RECEIVED',
              );
              debugPrint(
                '==============================================',
              );

              final String requestId =
                  accepted.requestId.trim();

              debugPrint(
                '📌 requestId = $requestId',
              );

              // ----------------------------------------------
              // REQUEST ID CHECK
              // ----------------------------------------------

              if (requestId.isEmpty) {
                debugPrint(
                  '❌ Owner navigation cancelled: requestId empty.',
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
                      '❌ Owner navigation cancelled: context unmounted.',
                    );
                    return;
                  }

                  debugPrint(
                    '✅ OWNER ACCEPTED REQUEST DETECTED',
                  );

                  _openOwnerAcceptedScreen(
                    context,
                    requestId,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OWNER ACCEPTED SCREEN
  // ============================================================
  //
  // IMPORTANT:
  // Yahan WalkerAcceptScreen intentionally nahi hai.
  //
  // Owner ka accepted screen milte hi isi method ke andar
  // us screen ko open karenge.
  //
  // ============================================================

  void _openOwnerAcceptedScreen(
    BuildContext context,
    String requestId,
  ) {
    debugPrint(
      '🚀 OWNER ACCEPTED SCREEN',
    );

    debugPrint(
      'requestId = $requestId',
    );

    /*
      TODO:
      Owner ke actual accepted/active-walk screen ka import
      aur navigation yahan add hoga.

      Example:

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OwnerAcceptScreen(
            requestId: requestId,
          ),
        ),
      );
    */

    // Temporary debug message so we can confirm that
    // Firestore accepted → Owner navigation callback
    // is definitely working.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Walker accepted the walk.',
        ),
      ),
    );
  }
}
