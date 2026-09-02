import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomeWelcomeCard extends StatelessWidget {
  const HomeWelcomeCard({
    super.key,
  });

  static const String dogAsset = 'assets/dog_welcome.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.only(
        left: 14,
        right: 5,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.slate,
            AppColors.navy,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(
              alpha: 0.10,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // =================================================
          // DOJO PAW
          // =================================================

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(
                alpha: 0.15,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.orange.withValues(
                  alpha: 0.38,
                ),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.orange,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          // =================================================
          // WELCOME MESSAGE
          // =================================================

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Dojo! 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Enjoy 30% OFF on your first week! 🎉',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // DOG
          // =================================================

          SizedBox(
            width: 76,
            height: 76,
            child: Image.asset(
              dogAsset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
