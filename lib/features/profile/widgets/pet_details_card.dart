import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';

class PetDetailsCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PetDetailsCard({
    super.key,
    required this.pet,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  String _value(List<String> keys) {
    for (final String key in keys) {
      final dynamic value = pet[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final String petName = _value([
      'name',
      'petName',
      'pet_name',
    ]);

    final String age = _value([
      'age',
      'petAge',
    ]);

    final String breed = _value([
      'breed',
      'petBreed',
    ]);

    final String behaviour = _value([
      'behaviour',
      'behavior',
      'petBehaviour',
    ]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DojoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DojoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // PET HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: DojoColors.lightOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: DojoColors.orange,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pet ${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: DojoColors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      petName == '-' ? 'Pet Name' : petName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: DojoColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // EDIT
              // ==================================================

              IconButton(
                tooltip: 'Edit Pet',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: DojoColors.orange,
                ),
              ),

              // ==================================================
              // DELETE
              // ==================================================

              IconButton(
                tooltip: 'Delete Pet',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: DojoStatusColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(height: 1),

          const SizedBox(height: 13),

          // ======================================================
          // AGE
          // ======================================================

          _PetRow(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: age,
          ),

          const SizedBox(height: 12),

          // ======================================================
          // BREED
          // ======================================================

          _PetRow(
            icon: Icons.pets_outlined,
            label: 'Breed',
            value: breed,
          ),

          const SizedBox(height: 12),

          // ======================================================
          // BEHAVIOUR
          // ======================================================

          _PetRow(
            icon: Icons.favorite_border_rounded,
            label: 'Behaviour',
            value: behaviour,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PET ROW
// ================================================================

class _PetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: DojoColors.orange,
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DojoColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: DojoColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
