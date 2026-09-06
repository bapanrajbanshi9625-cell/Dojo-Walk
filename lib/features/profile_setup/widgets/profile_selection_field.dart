import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class ProfileSelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;

  const ProfileSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue =
        value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ====================================================
        // LABEL
        // ====================================================

        Text(
          label,
          style: const TextStyle(
            color: DojoWalkColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        // ====================================================
        // SELECTION FIELD
        // ====================================================

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: DojoWalkColors.background,
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: hasValue
                    ? DojoWalkColors.primary.withValues(
                        alpha: 0.25,
                      )
                    : DojoWalkColors.border,
              ),
            ),
            child: Row(
              children: [
                // ==================================================
                // LEADING ICON
                // ==================================================

                Icon(
                  icon,
                  color: DojoWalkColors.primary,
                ),

                const SizedBox(width: 12),

                // ==================================================
                // VALUE / HINT
                // ==================================================

                Expanded(
                  child: Text(
                    hasValue
                        ? value!.trim()
                        : hint,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      // IMPORTANT:
                      // Selected value is explicitly dark
                      // so it remains visible immediately.
                      color: hasValue
                          ? DojoWalkColors.textPrimary
                          : DojoWalkColors.textSecondary,
                      fontSize: 15.5,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // ==================================================
                // ARROW
                // ==================================================

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: DojoWalkColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
