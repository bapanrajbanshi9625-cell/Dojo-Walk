// File:
// lib/features/profile/widgets/owner_info_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class OwnerInfoCard extends StatelessWidget {
  final String ownerId;
  final String mobileNumber;
  final String ownerName;
  final String ownerDob;
  final String ownerGender;
  final String memberSince;
  final bool isActive;

  final VoidCallback onChangeMobile;
  final VoidCallback onCopyOwnerId;

  const OwnerInfoCard({
    super.key,
    required this.ownerId,
    required this.mobileNumber,
    required this.ownerName,
    required this.ownerDob,
    required this.ownerGender,
    required this.memberSince,
    required this.isActive,
    required this.onChangeMobile,
    required this.onCopyOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DojoWalkColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoWalkColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // OWNER ID
          // ======================================================

          OwnerInfoRow(
            icon: Icons.badge_outlined,
            label: 'Owner ID',
            value: ownerId.isEmpty ? '-' : ownerId,
            trailing: ownerId.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Copy Owner ID',
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: DojoWalkColors.primary,
                    ),
                    onPressed: onCopyOwnerId,
                  ),
          ),

          const Divider(height: 20),

          // ======================================================
          // OWNER NAME
          // ======================================================

          OwnerInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner Name',
            value: ownerName.isEmpty ? '-' : ownerName,
          ),

          const Divider(height: 20),

          // ======================================================
          // MOBILE NUMBER
          // ======================================================

          OwnerInfoRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: mobileNumber.isEmpty
                ? '-'
                : mobileNumber,
            trailing: IconButton(
              tooltip: 'Change Mobile Number',
              icon: const Icon(
                Icons.edit_outlined,
                size: 19,
                color: DojoWalkColors.primary,
              ),
              onPressed: onChangeMobile,
            ),
          ),

          const Divider(height: 20),

          // ======================================================
          // DATE OF BIRTH
          // ======================================================

          OwnerInfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: ownerDob.isEmpty
                ? '-'
                : ownerDob,
          ),

          const Divider(height: 20),

          // ======================================================
          // GENDER
          // ======================================================

          OwnerInfoRow(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: ownerGender.isEmpty
                ? '-'
                : ownerGender,
          ),

          const Divider(height: 20),

          // ======================================================
          // MEMBER SINCE
          // ======================================================

          OwnerInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Member Since',
            value: memberSince.isEmpty
                ? '-'
                : memberSince,
          ),

          const Divider(height: 20),

          // ======================================================
          // ACCOUNT STATUS
          // ======================================================

          OwnerInfoRow(
            icon: isActive
                ? Icons.check_circle_outline_rounded
                : Icons.block_outlined,
            label: 'Account Status',
            value: isActive
                ? 'Active'
                : 'Inactive',
            valueColor: isActive
                ? DojoWalkColors.green
                : DojoWalkColors.red,
            iconColor: isActive
                ? DojoWalkColors.green
                : DojoWalkColors.red,
            iconBackgroundColor: isActive
                ? DojoWalkColors.greenLight
                : DojoWalkColors.redLight,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// OWNER INFO ROW
// ================================================================

class OwnerInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Color? valueColor;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const OwnerInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ========================================================
        // ICON
        // ========================================================

        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackgroundColor ??
                DojoWalkColors.primaryLight,
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ??
                DojoWalkColors.primary,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        // ========================================================
        // LABEL + VALUE
        // ========================================================

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color:
                      DojoWalkColors.textSecondary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ??
                      DojoWalkColors.black,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // TRAILING ACTION
        // ========================================================

        if (trailing != null)
          trailing!,
      ],
    );
  }
}
