import 'package:flutter/material.dart';

import 'core/network/network_monitor.dart';
import 'core/theme/dojo_theme.dart';
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
      // STARTUP
      // ========================================================

      home: const NetworkMonitor(
        child: SplashScreen(),
      ),
    );
  }
}
