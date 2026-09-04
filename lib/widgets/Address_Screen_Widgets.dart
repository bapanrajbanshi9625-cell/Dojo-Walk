import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AddressScreenWidgets {
  // =========================================================
  // BOOKING HEADER
  // =========================================================

  static Widget bookingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFFFF7A33),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: .20,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: .18,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Where should we walk?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Choose a saved address or use your current location.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CURRENT LOCATION CARD
  // =========================================================

  static Widget currentLocationCard({
    required bool gettingLocation,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: .18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: .035,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: gettingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color:
                            AppColors.primary,
                        size: 25,
                      ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Current Location',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Automatically detect your address',
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.slate,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  static Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.slate.withValues(
              alpha: .75,
            ),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INPUT FIELD
  // =========================================================

  static Widget field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = true,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 3,
            bottom: 7,
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (requiredField)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textCapitalization:
              TextCapitalization.sentences,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.slate.withValues(
                alpha: .50,
              ),
              fontSize: 13,
            ),
            counterText:
                maxLength != null ? '' : null,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: 14,
                right: 10,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.black.withValues(
                  alpha: .05,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SAVED ADDRESS CARD
  // =========================================================

  static Widget savedAddressCard({
    required int index,
    required Map<String, dynamic> address,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final String title =
        address['title']?.toString() ??
            'Address ${index + 1}';

    final String fullAddress =
        address['address']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: .10,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: .035,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color:
                                  AppColors.navy,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: .08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(20),
                          ),
                          child: const Text(
                            'SELECT',
                            style: TextStyle(
                              color:
                                  AppColors.primary,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fullAddress,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        smallAction(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onTap: onEdit,
                        ),
                        const SizedBox(width: 8),
                        smallAction(
                          icon:
                              Icons.delete_outline,
                          label: 'Delete',
                          danger: true,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SMALL ACTION
  // =========================================================

  static Widget smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final Color color =
        danger ? Colors.red : AppColors.navy;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
