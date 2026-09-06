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
    final double height = MediaQuery.of(context).size.height;

    return Material(
      color: lightGrey,
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
                    color: orange.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
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
                        color: orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        icon,
                        color: orange,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // ==================================================
                    // CLOSE BUTTON
                    // ==================================================

                    Material(
                      color: white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor,
                            size: 22,
                          ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: orange,
                                size: 42,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No options available',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 14,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final String item = items[index];

                            final bool isSelected = item == selected;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                              ),
                              child: Material(
                                color: isSelected
                                    ? darkOrange
                                    : white,
                                borderRadius: BorderRadius.circular(15),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () {
                                    onSelected(item);
                                  },
                                  child: Container(
                                    height: 57,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isSelected
                                            ? darkOrange
                                            : const Color(0xFFE5E7EB),
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
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? white.withValues(alpha: 0.18)
                                                : orange.withValues(alpha: 0.10),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            icon,
                                            color: isSelected
                                                ? white
                                                : orange,
                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // ==========================================
                                        // TEXT
                                        // ==========================================

                                        Expanded(
                                          child: Text(
                                            item,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? white
                                                  : textColor,
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        // ==========================================
                                        // CHECK
                                        // ==========================================

                                        Container(
                                          width: 27,
                                          height: 27,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? white
                                                : lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  color: orange,
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
