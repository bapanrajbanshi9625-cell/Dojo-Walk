import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';

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
        color: DojoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DojoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
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
                      color: DojoColors.orange,
                    ),
                    onPressed: onCopyOwnerId,
                  ),
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner Name',
            value: ownerName.isEmpty ? '-' : ownerName,
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: Icons.phone_outlined,
            label: 'Mobile Number',
            value: mobileNumber.isEmpty ? '-' : mobileNumber,
            trailing: IconButton(
              tooltip: 'Change Mobile Number',
              icon: const Icon(
                Icons.edit_outlined,
                size: 19,
                color: DojoColors.orange,
              ),
              onPressed: onChangeMobile,
            ),
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: ownerDob.isEmpty ? '-' : ownerDob,
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: Icons.wc_outlined,
            label: 'Gender',
            value: ownerGender.isEmpty ? '-' : ownerGender,
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Member Since',
            value: memberSince.isEmpty ? '-' : memberSince,
          ),

          const Divider(height: 20),

          OwnerInfoRow(
            icon: isActive
                ? Icons.check_circle_outline
                : Icons.block_outlined,
            label: 'Account Status',
            value: isActive ? 'Active' : 'Inactive',
            valueColor:
                isActive ? DojoColors.green : DojoColors.red,
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

  const OwnerInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DojoColors.lightOrange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: DojoColors.orange,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: DojoColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? DojoColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        if (trailing != null) trailing!,
      ],
    );
  }
}
