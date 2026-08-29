import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';

class ProfileCard extends StatelessWidget {
  final String ownerName;

  const ProfileCard({
    super.key,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName =
        ownerName.trim().isEmpty ? 'Owner' : ownerName.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DojoBrandColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: DojoBrandColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: DojoBrandColors.mintTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: DojoBrandColors.orange,
              size: 34,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: DojoBrandColors.slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DojoBrandColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: DojoBrandColors.mint,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Owner Profile',
                      style: TextStyle(
                        color: DojoBrandColors.slate,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
