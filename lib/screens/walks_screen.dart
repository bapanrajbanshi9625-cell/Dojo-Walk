import 'package:flutter/material.dart';

import '../features/insta_walk/controllers/insta_walk_container.dart';
import '../features/walks/widgets/walks_offer_slider.dart';

import 'custom_app_bar.dart';

class WalksScreen extends StatefulWidget {
  const WalksScreen({super.key});

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen> {
  static const Color background =
      Color(0xFFEDEFF2);

  // =====================================================
  // PULL TO REFRESH
  // =====================================================

  Future<void> _refreshWalks() async {
    if (!mounted) {
      return;
    }

    // Rebuild the complete Walks page.
    setState(() {});

    // Keep the refresh animation smooth.
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

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

      body: RefreshIndicator(
        color: Colors.orange,
        backgroundColor: Colors.white,
        onRefresh: _refreshWalks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            // Existing flow remains unchanged.
            // ==================================================

            const InstaWalkContainer(
              fullScreen: true,
            ),
          ],
        ),
      ),
    );
  }
}
