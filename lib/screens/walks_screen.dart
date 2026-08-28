import 'package:flutter/material.dart';

import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/active_walk/widgets/active_walker_container.dart';
import '../features/walks/widgets/walks_offer_slider.dart';

import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  static const Color background =
      Color(0xFFEDEFF2);

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
          12,
          15,
          110,
        ),
        children: [
          // ==================================================
          // OFFER / BANNER SLIDER
          // ==================================================

          const WalksOfferSlider(),

          const SizedBox(height: 12),

          // ==================================================
          // INSTA WALK
          // ==================================================

          InstaWalkContainer(
            fullScreen: true,
          ),

          const SizedBox(height: 4),

          // ==================================================
          // ACTIVE WALKER
          // ==================================================

          ActiveWalkerContainer(),
        ],
      ),
    );
  }
}
