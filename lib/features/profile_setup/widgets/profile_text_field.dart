import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

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
            color: DojoWalkColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          textCapitalization:
              TextCapitalization.words,

          // ====================================================
          // TYPED TEXT
          // ====================================================

          style: const TextStyle(
            color: DojoWalkColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),

          cursorColor: DojoWalkColors.primary,

          decoration: InputDecoration(
            // ==================================================
            // ORANGE ICON BACKGROUND + WHITE ICON
            // ==================================================

            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                top: 7,
                bottom: 7,
                right: 8,
              ),
              child: Container(
                width: 42,
                decoration: BoxDecoration(
                  color: DojoWalkColors.primary,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: DojoWalkColors.white,
                  size: 21,
                ),
              ),
            ),

            hintText: hint,

            hintStyle: const TextStyle(
              color: DojoWalkColors.textSecondary,
              fontSize: 15,
            ),

            filled: true,

            fillColor: DojoWalkColors.background,

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide:
                  const BorderSide(
                color: DojoWalkColors.border,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide:
                  const BorderSide(
                color: DojoWalkColors.primary,
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
