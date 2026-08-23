import 'package:flutter/material.dart';

import 'core/network/network_monitor.dart';
import 'core/theme/colors/dojo_brand_colors.dart';
import 'screens/splash_screen.dart';

class DojoWalk extends StatelessWidget {
  const DojoWalk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.orange,

        scaffoldBackgroundColor:
            const Color(0xFFF8FAF9),

        colorScheme: ColorScheme.fromSeed(
          seedColor: DojoBrandColors.orange,
          primary: DojoBrandColors.orange,
          secondary: DojoBrandColors.mint,
        ),
      ),

      home: const NetworkMonitor(
        child: SplashScreen(),
      ),
    );
  }
}
