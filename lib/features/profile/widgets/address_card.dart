import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AddressCard extends StatelessWidget {
  final String flatHouseNo;
  final String streetRoad;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final VoidCallback onEditAddress;

  const AddressCard({
    super.key,
    required this.flatHouseNo,
    required this.streetRoad,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.onEditAddress,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAddress =
        flatHouseNo.trim().isNotEmpty ||
        streetRoad.trim().isNotEmpty ||
        area.trim().isNotEmpty ||
        city.trim().isNotEmpty ||
        state.trim().isNotEmpty ||
        pincode.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========================================================
          // HEADER
          // ========================================================

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Address',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAddress
                          ? 'Your saved address'
                          : 'No saved address',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ====================================================
              // EDIT BUTTON
              // ====================================================

              Material(
                color: AppColors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onEditAddress,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.orange,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ========================================================
          // ADDRESS CONTENT
          // ========================================================

          if (!hasAddress)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    color: AppColors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'No address added yet.',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _AddressContent(
              flatHouseNo: flatHouseNo,
              streetRoad: streetRoad,
              area: area,
              city: city,
              state: state,
              pincode: pincode,
            ),
        ],
      ),
    );
  }
}

// ================================================================
// COMPACT ADDRESS CONTENT
// ================================================================

class _AddressContent extends StatelessWidget {
  final String flatHouseNo;
  final String streetRoad;
  final String area;
  final String city;
  final String state;
  final String pincode;

  const _AddressContent({
    required this.flatHouseNo,
    required this.streetRoad,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
  });

  @override
  Widget build(BuildContext context) {
    final List<_AddressItem> items = [];

    if (flatHouseNo.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.home_outlined,
          label: 'Flat / House',
          value: flatHouseNo.trim(),
        ),
      );
    }

    if (streetRoad.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.signpost_outlined,
          label: 'Street / Road',
          value: streetRoad.trim(),
        ),
      );
    }

    if (area.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.location_on_outlined,
          label: 'Area',
          value: area.trim(),
        ),
      );
    }

    if (city.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.location_city_outlined,
          label: 'City',
          value: city.trim(),
        ),
      );
    }

    if (state.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.map_outlined,
          label: 'State',
          value: state.trim(),
        ),
      );
    }

    if (pincode.trim().isNotEmpty) {
      items.add(
        _AddressItem(
          icon: Icons.markunread_mailbox_outlined,
          label: 'Pincode',
          value: pincode.trim(),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          _AddressRow(
            item: items[i],
          ),
        ],
      ],
    );
  }
}

// ================================================================
// ADDRESS ITEM
// ================================================================

class _AddressItem {
  final IconData icon;
  final String label;
  final String value;

  const _AddressItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ================================================================
// ADDRESS ROW
// ================================================================

class _AddressRow extends StatelessWidget {
  final _AddressItem item;

  const _AddressRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            item.icon,
            color: AppColors.orange,
            size: 17,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${item.label}  ',
                  style: const TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: item.value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
