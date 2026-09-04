import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/network_monitor.dart';
import 'core/theme/dojo_theme.dart';
import 'features/accept_live_strip/widgets/accept_live_strip.dart';
import 'screens/splash_screen.dart';

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
      // STATUS BAR + GLOBAL ACCEPT / LIVE STRIP
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
              // GLOBAL ACCEPT / LIVE WALK STRIP
              //
              // Independent from MainNavigationScreen.
              //
              // WALK ACCEPTED:
              // Opens WalkerAcceptScreen
              //
              // LIVE WALK:
              // Opens LiveWalkScreen
              //
              // COMPLETED:
              // Strip automatically hides.
              // ==================================================

              const Positioned(
                left: 0,
                right: 0,
                bottom: 80,
                child: AcceptLiveStrip(),
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
