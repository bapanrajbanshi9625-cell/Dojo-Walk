import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class ProfileWelcomeCard extends StatelessWidget {
  const ProfileWelcomeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DojoWalkColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ====================================================
          // PAW ICON
          // ORANGE BACKGROUND + WHITE PAW
          // ====================================================

          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: DojoWalkColors.primaryDark,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: DojoWalkColors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    color: DojoWalkColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Add your details and your pets.',
                  style: TextStyle(
                    color: DojoWalkColors.primaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
