import 'package:flutter/material.dart';

import '../core/theme/dojo_walk_design_system.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DojoWalkColors.primary,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: DojoWalkColors.white,
          ),
        ),
        iconTheme: const IconThemeData(
          color: DojoWalkColors.white,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: DojoWalkColors.blue,
              child: Icon(
                Icons.notifications,
                color: DojoWalkColors.white,
              ),
            ),
            title: Text('Walk Started'),
            subtitle: Text(
              'Your scheduled walk session with Buddy has started successfully.',
            ),
          ),
        ],
      ),
    );
  }
}
