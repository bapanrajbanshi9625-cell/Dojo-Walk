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

  final TextEditingController searchController = TextEditingController();

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
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: orange,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Choose Breed',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Select your dog\'s breed',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Material(
                      color: white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE7E8EB),
                    ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: orange,
                    decoration: InputDecoration(
                      hintText: 'Search breed...',
                      hintStyle: const TextStyle(
                        color: textGrey,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: textGrey,
                        size: 23,
                      ),
                      suffixIcon: search.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  search = '';
                                });
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: textGrey,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredBreeds.length} breeds available',
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: filteredBreeds.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: 2,
                            bottom: 12,
                          ),
                          itemCount: filteredBreeds.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final breed = filteredBreeds[index];

                            final bool isSelected =
                                widget.selectedBreed == breed;

                            return _buildBreedCard(
                              breed: breed,
                              isSelected: isSelected,
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

  Widget _buildBreedCard({
    required String breed,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? darkOrange : white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () {
          widget.onSelected(breed);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isSelected
                  ? darkOrange
                  : const Color(0xFFE7E8EB),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.16)
                      : orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: isSelected ? white : orange,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  breed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? white : textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              if (isSelected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: white,
                    size: 19,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: textGrey,
                  size: 23,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: orange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: orange,
                size: 34,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No breed found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Try searching with a different breed name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
