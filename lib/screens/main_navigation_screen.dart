import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/accept_live_strip/widgets/accept_live_strip.dart';
import '../features/walker_accept/screens/walker_accept_entry.dart';

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
  // REFRESH VERSION
  //
  // Every tap increases the selected screen's version.
  // Changing the key forces that screen to be recreated.
  // ==========================================================

  final List<int> _refreshVersions = <int>[0, 0, 0];

  // ==========================================================
  // CREATE SCREEN
  // ==========================================================

  Widget _buildScreen(int index) {
    final Key key = ValueKey<String>(
      '${index}_${_refreshVersions[index]}',
    );

    switch (index) {
      case 0:
        return HomeScreen(key: key);

      case 1:
        return WalksScreen(key: key);

      case 2:
        return MenuScreen(key: key);

      default:
        return HomeScreen(key: key);
    }
  }

  // ==========================================================
  // NAVIGATION TAP
  // ==========================================================

  void _onNavigationTap(int index) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;

      // Refresh every time the tab is tapped.
      _refreshVersions[index]++;
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

      body: Stack(
        children: [
          // ======================================================
          // MAIN SCREENS
          //
          // Selected screen gets a new key on every tap.
          // ======================================================

          IndexedStack(
            index: _currentIndex,
            children: [
              _buildScreen(0),
              _buildScreen(1),
              _buildScreen(2),
            ],
          ),

          // ======================================================
          // ACCEPT / LIVE STRIP
          //
          // Existing realtime listener remains untouched.
          // ======================================================

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AcceptLiveStrip(),
            ),
          ),

          // ======================================================
          // WALKER ACCEPT ENTRY
          // ======================================================

          const WalkerAcceptEntry(),
        ],
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: SizedBox(
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
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.black54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            type: BottomNavigationBarType.fixed,
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
    );
  }
}
