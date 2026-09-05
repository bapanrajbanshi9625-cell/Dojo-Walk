import 'package:flutter/material.dart';

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

  static const Color orange = Color(0xFFF4511E);
  static const Color darkOrange = Color(0xFFE64617);
  static const Color white = Colors.white;
  static const Color textColor = Color(0xFF222222);
  static const Color textGrey = Color(0xFF707070);
  static const Color lightGrey = Color(0xFFF6F7F9);

  @override
  Widget build(BuildContext context) {
    final double height =
        MediaQuery.of(context).size.height;

    return Material(
      color: orange,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height * 0.82,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              8,
            ),
            child: Column(
              children: [
                // ==================================================
                // HANDLE
                // ==================================================

                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: white.withValues(
                      alpha: 0.75,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // HEADER
                // ==================================================

                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: white.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: white.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: white,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    // ==================================================
                    // CLOSE BUTTON
                    // ==================================================

                    InkWell(
                      borderRadius:
                          BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration:
                            BoxDecoration(
                          color: white.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: white.withValues(
                              alpha: 0.28,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ==================================================
                // OPTIONS
                // ==================================================

                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'No options available',
                            style: TextStyle(
                              color: white,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics:
                              const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.only(
                            top: 4,
                            bottom: 14,
                          ),
                          itemCount: items.length,
                          itemBuilder:
                              (context, index) {
                            final String item =
                                items[index];

                            final bool isSelected =
                                item == selected;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 8,
                              ),
                              child: Material(
                                color: isSelected
                                    ? darkOrange
                                    : white,
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                                clipBehavior:
                                    Clip.antiAlias,
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  onTap: () {
                                    onSelected(item);
                                  },
                                  child: Container(
                                    height: 57,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        15,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? white.withValues(
                                                alpha: 0.30,
                                              )
                                            : const Color(
                                                0xFFE5E7EB,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // ==========================================
                                        // ICON
                                        // ==========================================

                                        Container(
                                          width: 39,
                                          height: 39,
                                          decoration:
                                              BoxDecoration(
                                            color: isSelected
                                                ? white.withValues(
                                                    alpha: 0.18,
                                                  )
                                                : orange,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            color: white,
                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 12,
                                        ),

                                        // ==========================================
                                        // TEXT
                                        // ==========================================

                                        Expanded(
                                          child: Text(
                                            item,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                TextStyle(
                                              color:
                                                  isSelected
                                                      ? white
                                                      : textColor,
                                              fontSize: 14,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight
                                                          .w800
                                                      : FontWeight
                                                          .w600,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 8,
                                        ),

                                        // ==========================================
                                        // CHECK
                                        // ==========================================

                                        Container(
                                          width: 27,
                                          height: 27,
                                          decoration:
                                              BoxDecoration(
                                            color: isSelected
                                                ? white
                                                : lightGrey,
                                            shape:
                                                BoxShape.circle,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons
                                                      .check_rounded,
                                                  color:
                                                      orange,
                                                  size: 18,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
