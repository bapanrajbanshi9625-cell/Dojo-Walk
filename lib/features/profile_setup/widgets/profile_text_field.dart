import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          textCapitalization:
              TextCapitalization.words,

          // ====================================================
          // IMPORTANT:
          // Typed text must always remain visible.
          // ====================================================

          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          cursorColor: AppColors.primary,

          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColors.primary,
            ),

            hintText: hint,

            hintStyle: const TextStyle(
              color: AppColors.grey,
              fontSize: 15,
            ),

            filled: true,

            fillColor: AppColors.lightGrey,

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide:
                  const BorderSide(
                color: AppColors.border,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide:
                  const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),

            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}
