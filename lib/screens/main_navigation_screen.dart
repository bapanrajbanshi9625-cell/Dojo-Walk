// File location:
// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/active_live_walk_strip.dart';

import 'home_screen.dart';
import 'menu_screen.dart';
import 'walks_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.isWalker = false,
  });

  final bool isWalker;

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  // ==========================================================
  // CURRENT TAB
  // ==========================================================

  int _currentIndex = 0;

  // ==========================================================
  // MAIN SCREENS
  // ==========================================================

  late final List<Widget> _screens;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _screens = <Widget>[
      const HomeScreen(),
      const WalksScreen(),
      const MenuScreen(),
    ];
  }

  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  void _onNavigationTap(int index) {
    if (!mounted || _currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // MAIN CONTENT
      // ========================================================

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ========================================================
      // BOTTOM AREA
      //
      // ActiveLiveWalkStrip:
      // - Active होते ही दिखाई देगी
      // - Accepted / On The Way / Reached / Walking /
      //   In Progress के दौरान बनी रहेगी
      // - Completed / Ended / Cancelled पर hide होगी
      //
      // Strip और navigation के बीच ZERO GAP.
      // ========================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // ACTIVE / LIVE WALK STRIP
          // ======================================================

          SizedBox(
            width: double.infinity,
            child: ActiveLiveWalkStrip(
              isWalker: widget.isWalker,
            ),
          ),

          // ======================================================
          // BOTTOM NAVIGATION
          // ======================================================

          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border,
                    width: 0.6,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                elevation: 0,

                currentIndex: _currentIndex,

                selectedItemColor:
                    AppColors.primary,

                unselectedItemColor:
                    Colors.black54,

                selectedLabelStyle:
                    const TextStyle(
                  fontWeight: FontWeight.w700,
                ),

                unselectedLabelStyle:
                    const TextStyle(
                  fontWeight: FontWeight.w500,
                ),

                type:
                    BottomNavigationBarType.fixed,

                onTap: _onNavigationTap,

                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.home_rounded,
                    ),
                    label: 'Home',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.directions_walk_rounded,
                    ),
                    label: 'Walks',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.menu_rounded,
                    ),
                    label: 'Menu',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
