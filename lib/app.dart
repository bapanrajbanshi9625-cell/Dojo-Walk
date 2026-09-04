import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      // GLOBAL SYSTEM UI
      // ========================================================

      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Color(0xFFFF7A00),
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
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
