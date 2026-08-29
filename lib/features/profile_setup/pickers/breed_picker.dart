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
  static const Color lightOrange = Color(0xFFFFF1E8);
  static const Color textColor = Color(0xFF222222);
  static const Color textGrey = Color(0xFF707070);
  static const Color backgroundColor = Colors.white;

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
    final filteredBreeds = widget.breeds.where((breed) {
      return breed.toLowerCase().contains(
            search.toLowerCase(),
          );
    }).toList();

    final height = MediaQuery.of(context).size.height;

    return Material(
      color: backgroundColor,
      child: SizedBox(
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
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------

                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 13),

                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: lightOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: orange,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 11),

                    const Expanded(
                      child: Text(
                        'Choose Breed',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ------------------------------------------------
                // SEARCH
                // ------------------------------------------------

                SizedBox(
                  height: 44,
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
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: orange,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: orange,
                        size: 21,
                      ),
                      hintText: 'Search breed...',
                      hintStyle: const TextStyle(
                        color: textGrey,
                        fontSize: 13.5,
                      ),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Color(0xFFF7F7F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(
                          color: orange,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ------------------------------------------------
                // COUNT
                // ------------------------------------------------

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    search.isEmpty
                        ? 'All Breeds'
                        : '${filteredBreeds.length} breeds found',
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ------------------------------------------------
                // BREED LIST
                // ------------------------------------------------

                Expanded(
                  child: filteredBreeds.isEmpty
                      ? const Center(
                          child: Text(
                            'No breed found',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics:
                              const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 2,
                            bottom: 8,
                          ),
                          itemCount: filteredBreeds.length,
                          separatorBuilder: (_, __) =>
                              const Divider(
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final breed =
                                filteredBreeds[index];

                            final selected =
                                breed == widget.selectedBreed;

                            return Material(
                              color: selected
                                  ? lightOrange
                                  : backgroundColor,
                              borderRadius:
                                  BorderRadius.circular(12),
                              child: SizedBox(
                                height: 47,
                                child: ListTile(
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  onTap: () {
                                    widget.onSelected(breed);
                                  },

                                  // --------------------------------
                                  // PET ICON
                                  // --------------------------------

                                  leading: Container(
                                    width: 34,
                                    height: 34,
                                    decoration:
                                        const BoxDecoration(
                                      color: lightOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.pets_rounded,
                                      color: orange,
                                      size: 17,
                                    ),
                                  ),

                                  // --------------------------------
                                  // BREED NAME
                                  // --------------------------------

                                  title: Text(
                                    breed,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected
                                          ? orange
                                          : textColor,
                                      fontSize: 13.5,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),

                                  // --------------------------------
                                  // SELECTED CHECK
                                  // --------------------------------

                                  trailing: selected
                                      ? const Icon(
                                          Icons
                                              .check_circle_rounded,
                                          color: orange,
                                          size: 20,
                                        )
                                      : null,
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
