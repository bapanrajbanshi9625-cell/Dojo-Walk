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
  // CURRENT SCREEN
  // ==========================================================

  int _currentIndex = 0;

  // ==========================================================
  // SCREENS
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
  // NAVIGATION
  // ==========================================================

  void _onNavigationTap(int index) {
    if (_currentIndex == index) {
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
      // ACTIVE / LIVE WALK STRIP + NAVIGATION
      //
      // IMPORTANT:
      // No gap between strip and bottom navigation.
      //
      // Strip remains visible from:
      //
      // active
      // accepted
      // on_the_way
      // reached
      // walking
      // in_progress
      //
      // It disappears only when the walk is completed/ended/
      // cancelled.
      // ========================================================

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ======================================================
          // ACTIVE / LIVE WALK STRIP
          // ======================================================

          ActiveLiveWalkStrip(
            isWalker: widget.isWalker,
          ),

          // ======================================================
          // BOTTOM NAVIGATION
          // ======================================================

          Container(
            width: double.infinity,
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
        ],
      ),
    );
  }
}
