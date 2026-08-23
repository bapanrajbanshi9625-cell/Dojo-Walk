import 'dart:async';

import 'package:flutter/material.dart';

class WalksOfferItem {
  final String image;
  final String title;
  final String subtitle;

  const WalksOfferItem({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

class WalksOfferSlider extends StatefulWidget {
  const WalksOfferSlider({super.key});

  @override
  State<WalksOfferSlider> createState() =>
      _WalksOfferSliderState();
}

class _WalksOfferSliderState extends State<WalksOfferSlider> {
  final PageController _controller = PageController();

  Timer? _timer;
  int _currentIndex = 0;

  // ==========================================================
  // BANNERS
  // ==========================================================

  static const List<WalksOfferItem> _items = [
    WalksOfferItem(
      image: 'assets/walk_banner_1.png',
      title: 'Find a walker instantly',
      subtitle: 'Get a nearby walker for your dog.',
    ),
    WalksOfferItem(
      image: 'assets/walk_banner_2.png',
      title: 'Special Walk Offer',
      subtitle: 'Book your next walk easily.',
    ),
    WalksOfferItem(
      image: 'assets/walk_banner_3.png',
      title: 'Track your dog walk',
      subtitle: 'Stay connected during the walk.',
    ),
  ];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  // ==========================================================
  // AUTO CHANGE — EVERY 5 SECONDS
  // ==========================================================

  void _startAutoScroll() {
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted || !_controller.hasClients) {
          return;
        }

        final int nextIndex =
            (_currentIndex + 1) % _items.length;

        _controller.animateToPage(
          nextIndex,
          duration: const Duration(
            milliseconds: 700,
          ),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }

  // ==========================================================
  // PAGE CHANGE
  // ==========================================================

  void _onPageChanged(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: PageView.builder(
          controller: _controller,
          itemCount: _items.length,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (
            BuildContext context,
            int index,
          ) {
            return _buildBanner(_items[index]);
          },
        ),
      ),
    );
  }

  // ==========================================================
  // BANNER
  // ==========================================================

  Widget _buildBanner(WalksOfferItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF243746),
            Color(0xFF304E5A),
            Color(0xFF376A70),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF65D6C8)
              .withValues(alpha: .18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==================================================
          // IMAGE
          // ==================================================

          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
            child: Image.asset(
              item.image,
              width: 78,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  width: 78,
                  height: 76,
                  color: const Color(0xFF304E5A),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: Color(0xFF65D6C8),
                    size: 28,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // TEXT
          // ==================================================

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==================================================
          // ARROW
          // ==================================================

          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),
        ],
      ),
    );
  }
}
