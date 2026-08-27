import 'package:flutter/material.dart';

import '../../../core/theme/colors/dojo_brand_colors.dart';

class AddPetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddPetButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: DojoBrandColors.orange,
          side: const BorderSide(
            color: DojoBrandColors.orange,
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 23,
        ),
        label: const Text(
          'Add Pet',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
