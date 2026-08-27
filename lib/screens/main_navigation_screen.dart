// File location:
// lib/screens/main_navigation_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/home/services/home_live_walk_service.dart';
import '../features/home/widgets/home_live_walk_bar.dart';

import 'home_screen.dart';
import 'live_walk_screen.dart';
import 'menu_screen.dart';
import 'walks_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
  });

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
  // LIVE WALK SERVICE
  // ==========================================================

  final HomeLiveWalkService _liveWalkService =
      HomeLiveWalkService.instance;

  // ==========================================================
  // AUTO OPEN CONTROL
  // ==========================================================

  String? _autoOpenedWalkId;

  bool _isOpeningLiveWalk = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _screens = [
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
  // STRING READER
  // ==========================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value != null) {
        final String result = value.toString().trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return '';
  }

  // ==========================================================
  // GET WALK ID
  // ==========================================================

  String _getWalkId(
    Map<String, dynamic> data,
  ) {
    return _readString(
      data,
      const [
        'walkId',
        'walkID',
        'id',
        '_documentId',
      ],
    );
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  Future<void> _openLiveWalk(
    Map<String, dynamic> data, {
    bool automatic = false,
  }) async {
    if (!mounted || _isOpeningLiveWalk) {
      return;
    }

    final String walkId = _getWalkId(data);

    if (walkId.isEmpty) {
      return;
    }

    if (automatic) {
      _autoOpenedWalkId = walkId;
    }

    _isOpeningLiveWalk = true;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveWalkScreen(
            walkId: walkId,

            walkerUid: _readString(
              data,
              const [
                'walkerUid',
                'walkerUID',
                'walkerId',
              ],
            ),

            walkerName: _readString(
              data,
              const [
                'walkerName',
                'name',
              ],
            ).isEmpty
                ? 'Walker'
                : _readString(
                    data,
                    const [
                      'walkerName',
                      'name',
                    ],
                  ),

            walkerPhone: _readString(
              data,
              const [
                'walkerPhone',
                'phone',
                'phoneNumber',
              ],
            ).isEmpty
                ? null
                : _readString(
                    data,
                    const [
                      'walkerPhone',
                      'phone',
                      'phoneNumber',
                    ],
                  ),
          ),
        ),
      );
    } finally {
      _isOpeningLiveWalk = false;
    }
  }

  // ==========================================================
  // ACTIVE WALK HANDLER
  // ==========================================================

  void _handleActiveWalk(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      _autoOpenedWalkId = null;
      return;
    }

    final String walkId = _getWalkId(data);

    if (walkId.isEmpty ||
        _autoOpenedWalkId == walkId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isOpeningLiveWalk) {
        return;
      }

      _openLiveWalk(
        data,
        automatic: true,
      );
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ========================================================
      // LIVE BAR + BOTTOM NAVIGATION
      //
      // NO GAP BETWEEN THEM
      // ========================================================

      bottomNavigationBar:
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
        stream: _liveWalkService.liveWalkStream(),

        builder: (
          BuildContext context,
          AsyncSnapshot<
                  QuerySnapshot<Map<String, dynamic>>>
              snapshot,
        ) {
          Map<String, dynamic>? liveWalkData;

          if (snapshot.hasData &&
              !snapshot.hasError) {
            liveWalkData =
                _liveWalkService.getLiveWalkData(
              snapshot.data!,
            );
          }

          final bool isActive =
              liveWalkData != null;

          if (isActive) {
            _handleActiveWalk(
              liveWalkData,
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // LIVE WALK BAR
              // ==================================================

              if (isActive)
                HomeLiveWalkBar(
                  onTap: () {
                    _openLiveWalk(
                      liveWalkData!,
                    );
                  },
                ),

              // ==================================================
              // BOTTOM NAVIGATION
              // ==================================================

              Container(
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
