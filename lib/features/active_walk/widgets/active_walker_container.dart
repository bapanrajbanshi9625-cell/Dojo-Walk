import 'package:flutter/material.dart';

import '../models/active_walk.dart';

class ActiveWalkerContainer
    extends StatelessWidget {
  const ActiveWalkerContainer({
    super.key,
    required this.walk,
  });

  final ActiveWalk walk;

  static const Color navy =
      Color(0xFF263746);

  static const Color primary =
      Color(0xFFFF8A00);

  static const Color green =
      Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primary,
              size: 29,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'WALKER',
                  style: TextStyle(
                    color: Colors.black45,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  walk.walkerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                if (walk.walkerUid.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 3,
                    ),
                    child: Text(
                      'UID: ${walk.walkerUid}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color:
                  green.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: green,
                fontSize: 9,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
