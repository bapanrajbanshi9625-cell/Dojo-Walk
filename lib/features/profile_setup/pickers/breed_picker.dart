import 'package:flutter/material.dart';

class BreedPicker extends StatefulWidget {
  final List<String> breeds;
  final String? selectedBreed;
  final ValueChanged<String> onSelected;

  const BreedPicker({
    super.key,
    required this.breeds,
    required this.selectedBreed,
    required this.onSelected,
  });

  @override
  State<BreedPicker> createState() => _BreedPickerState();
}

class _BreedPickerState extends State<BreedPicker> {
  static const Color orange = Color(0xFFF4511E);
  static const Color darkOrange = Color(0xFFE64617);
  static const Color white = Colors.white;
  static const Color textColor = Color(0xFF222222);
  static const Color textGrey = Color(0xFF707070);
  static const Color lightGrey = Color(0xFFF6F7F9);

  final TextEditingController searchController =
      TextEditingController();

  String search = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filteredBreeds = widget.breeds.where((breed) {
      return breed.toLowerCase().contains(
            search.trim().toLowerCase(),
          );
    }).toList();

    final double height = MediaQuery.of(context).size.height;

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
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
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
                        color: white.withValues(
                          alpha: 0.18,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: white.withValues(
                            alpha: 0.30,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: white,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Breed',
                            style: TextStyle(
                              color: white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Select your dog\'s breed',
                            style: TextStyle(
                              color: white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // CLOSE BUTTON
                    // ==================================================

                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: white.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius: BorderRadius.circular(14),
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
                // SEARCH
                // ==================================================

                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        search = value;
                      });
                    },
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: orange,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: orange,
                        size: 22,
                      ),
                      hintText: 'Search breed...',
                      hintStyle: const TextStyle(
                        color: textGrey,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: darkOrange,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // COUNT
                // ==================================================

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    search.trim().isEmpty
                        ? '${filteredBreeds.length} Breeds'
                        : '${filteredBreeds.length} breeds found',
                    style: const TextStyle(
                      color: white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ==================================================
                // BREED LIST
                // ==================================================

                Expanded(
                  child: filteredBreeds.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                color: white,
                                size: 38,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No breed found',
                                style: TextStyle(
                                  color: white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics:
                              const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 14,
                          ),
                          itemCount: filteredBreeds.length,
                          itemBuilder: (context, index) {
                            final String breed =
                                filteredBreeds[index];

                            final bool selected =
                                breed == widget.selectedBreed;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                              ),
                              child: Material(
                                color: selected
                                    ? darkOrange
                                    : white,
                                borderRadius:
                                    BorderRadius.circular(15),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    widget.onSelected(breed);
                                  },
                                  child: Container(
                                    height: 57,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                      border: Border.all(
                                        color: selected
                                            ? white.withValues(
                                                alpha: 0.35,
                                              )
                                            : const Color(
                                                0xFFE5E7EB,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // ==========================================
                                        // PAW
                                        // ==========================================

                                        Container(
                                          width: 39,
                                          height: 39,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? white.withValues(
                                                    alpha: 0.18,
                                                  )
                                                : orange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.pets_rounded,
                                            color: white,
                                            size: 20,
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // ==========================================
                                        // BREED NAME
                                        // ==========================================

                                        Expanded(
                                          child: Text(
                                            breed,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: selected
                                                  ? white
                                                  : textColor,
                                              fontSize: 14,
                                              fontWeight: selected
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
                                            color: selected
                                                ? white
                                                : lightGrey,
                                            shape: BoxShape.circle,
                                          ),
                                          child: selected
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
