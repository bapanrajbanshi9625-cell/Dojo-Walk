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

      body: Stack(
        children: [
          // ======================================================
          // MAIN SCREENS
          // ======================================================

          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // ======================================================
          // ACCEPT / LIVE STRIP
          //
          // Persistent across Home / Walks / Menu.
          //
          // Service automatically decides:
          //
          // ACCEPTED → visible
          // LIVE     → visible
          // COMPLETED → hidden
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
          //
          // Persistent listener for accepted walk requests.
          // Completely independent from Insta Walk.
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
