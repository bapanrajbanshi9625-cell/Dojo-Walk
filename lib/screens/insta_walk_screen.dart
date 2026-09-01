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

            onAccepted: (accepted) {
              final String requestId =
                  accepted.requestId.trim();

              debugPrint('');
              debugPrint('==============================================');
              debugPrint('🔥 INSTA WALK SCREEN RECEIVED ACCEPTED');
              debugPrint('requestId = $requestId');
              debugPrint('==============================================');

              if (requestId.isEmpty) {
                debugPrint(
                  '❌ Navigation cancelled: requestId empty.',
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return WalkerAcceptScreen(
                      requestId: requestId,
                    );
                  },
                ),
              );

              debugPrint(
                '🚀 Navigation command executed.',
              );
            },
          ),
        ),
      ),
    );
  }
}
