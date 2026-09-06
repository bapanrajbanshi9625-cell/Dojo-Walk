import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

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
        color: DojoWalkColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoWalkColors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DojoWalkColors.primaryLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: DojoWalkColors.primary,
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
                        color: DojoWalkColors.textSecondary,
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
                        color: DojoWalkColors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // EDIT
              // ==================================================

              _ActionButton(
                icon: Icons.edit_outlined,
                color: DojoWalkColors.primary,
                tooltip: 'Edit Pet',
                onPressed: onEdit,
              ),

              const SizedBox(width: 6),

              // ==================================================
              // DELETE
              // ==================================================

              _ActionButton(
                icon: Icons.delete_outline_rounded,
                color: DojoWalkColors.red,
                tooltip: 'Delete Pet',
                onPressed: onDelete,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            height: 1,
            color: DojoWalkColors.black.withValues(alpha: 0.07),
          ),

          const SizedBox(height: 14),

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
// ACTION BUTTON
// ================================================================

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ICON
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: DojoWalkColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: DojoWalkColors.primary,
          ),
        ),

        const SizedBox(width: 11),

        // LABEL
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DojoWalkColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 6),

        // VALUE
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: DojoWalkColors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
