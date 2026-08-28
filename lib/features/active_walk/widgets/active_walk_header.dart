import 'package:flutter/material.dart';

import '../models/active_walk.dart';

class ActiveWalkHeader extends StatelessWidget {
  const ActiveWalkHeader({
    super.key,
    required this.walk,
    required this.isWalker,
    required this.onBack,
  });

  final ActiveWalk walk;
  final bool isWalker;
  final VoidCallback onBack;

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: navy,
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isWalker
                      ? 'ACTIVE WALK'
                      : 'WALKER ON THE WAY',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${walk.dogName} • ${walk.dogBreed}',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
                  green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: green,
                  size: 7,
                ),
                SizedBox(width: 4),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: green,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
