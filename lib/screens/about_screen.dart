import 'package:flutter/material.dart';

import '../core/theme/dojo_walk_design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkColors.background,

      appBar: AppBar(
        backgroundColor: DojoWalkColors.primary,
        foregroundColor: DojoWalkColors.white,
        title: const Text(
          'About Dojo Walk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: DojoWalkColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                color: DojoWalkColors.primary,
                size: 60,
              ),

              SizedBox(height: 15),

              Text(
                'Dojo Walk',
                style: TextStyle(
                  color: DojoWalkColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Dog walking made simple.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DojoWalkColors.textSecondary,
                ),
              ),

              SizedBox(height: 18),

              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: DojoWalkColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
