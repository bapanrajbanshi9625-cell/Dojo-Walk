import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CompactPickerSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  const CompactPickerSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double height =
        MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.35,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            10,
          ),
          child: Column(
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 13),

              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        const BoxDecoration(
                      color: AppColors.orangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // ==================================================
              // OPTIONS
              // ==================================================

              Expanded(
                child: ListView.separated(
                  physics:
                      const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 3,
                    bottom: 8,
                  ),
                  itemCount: items.length,
                  separatorBuilder:
                      (_, __) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  itemBuilder:
                      (context, index) {
                    final String item =
                        items[index];

                    final bool isSelected =
                        item == selected;

                    return SizedBox(
                      height: 48,
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        onTap: () =>
                            onSelected(item),

                        // ==================================================
                        // RADIO
                        // ==================================================

                        leading: Icon(
                          isSelected
                              ? Icons
                                  .radio_button_checked_rounded
                              : Icons
                                  .radio_button_off_rounded,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey,
                          size: 21,
                        ),

                        // ==================================================
                        // OPTION TEXT
                        // ==================================================

                        title: Text(
                          item,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.slate,
                            fontSize: 14.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),

                        // ==================================================
                        // CHECK
                        // ==================================================

                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color:
                                    AppColors.primary,
                                size: 21,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
