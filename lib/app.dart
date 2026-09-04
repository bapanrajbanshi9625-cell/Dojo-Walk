import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/network_monitor.dart';
import 'core/theme/dojo_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/active_live_walk_strip.dart';

class DojoWalk extends StatelessWidget {
  const DojoWalk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo',

      debugShowCheckedModeBanner: false,

      // ========================================================
      // DOJO THEME
      // ========================================================

      theme: DojoTheme.light(),
      darkTheme: DojoTheme.dark(),
      themeMode: ThemeMode.system,

      // ========================================================
      // STATUS BAR
      // ========================================================

      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFFF7A00),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Stack(
            children: [
              // ==================================================
              // APP CONTENT
              // ==================================================

              Positioned.fill(
                child: child ?? const SizedBox.shrink(),
              ),

              // ==================================================
              // FLOATING ACTIVE / LIVE WALK STRIP
              //
              // Completely independent from
              // MainNavigationScreen.
              //
              // It stays just above the bottom navigation area.
              // ==================================================

              const Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: ActiveLiveWalkStrip(),
              ),
            ],
          ),
        );
      },

      // ========================================================
      // STARTUP
      // ========================================================

      home: const NetworkMonitor(
        child: SplashScreen(),
      ),
    );
  }
}
