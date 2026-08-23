// File location: lib/screens/walks_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/walks/containers/active_walker_container.dart';

import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);

  static const Color primary = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: const CustomAppBar(),

      // =====================================================
      // BODY
      // =====================================================

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          15,
          18,
          15,
          110,
        ),
        children: [
          // ==================================================
          // TITLE
          // ==================================================

          Row(
            children: [
              Container(
                height: 21,
                width: 4,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      BorderRadius.circular(5),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              const Text(
                'Walks',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Find and manage your dog walks.',
            style: TextStyle(
              color: slate,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ==================================================
          // INSTA WALK
          // ==================================================

          InstaWalkContainer(
            fullScreen: true,
          ),

          // ==================================================
          // ACTIVE WALKER
          // ==================================================

          const SizedBox(
            height: 4,
          ),

          ActiveWalkerContainer(),
        ],
      ),
    );
  }
}
