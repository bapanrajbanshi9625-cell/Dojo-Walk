import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';
import '../models/pet_data.dart';
import 'profile_text_field.dart';
import 'profile_selection_field.dart';

class PetCard extends StatelessWidget {
  final PetData pet;
  final int index;
  final int totalPets;
  final VoidCallback onRemove;
  final VoidCallback onAgeTap;
  final VoidCallback onBreedTap;
  final VoidCallback onBehaviourTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.index,
    required this.totalPets,
    required this.onRemove,
    required this.onAgeTap,
    required this.onBreedTap,
    required this.onBehaviourTap,
  });

  @override
  Widget build(BuildContext context) {
    final int petNumber = index + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DojoWalkColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DojoWalkColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(
              alpha: 0.045,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ====================================================
          // PET HEADER
          // ====================================================

          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: const BoxDecoration(
                  color: DojoWalkColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: DojoWalkColors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Pet $petNumber',
                  style: const TextStyle(
                    color: DojoWalkColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // ==================================================
              // REMOVE
              // ==================================================

              if (totalPets > 1)
                TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor:
                        DojoWalkColors.red,
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 17),

          // ====================================================
          // PET NAME
          // ====================================================

          ProfileTextField(
            controller: pet.nameController,
            label: 'Pet Name',
            hint: 'Enter pet name',
            icon: Icons.pets_rounded,
          ),

          const SizedBox(height: 17),

          // ====================================================
          // PET AGE
          // ====================================================

          ProfileSelectionField(
            label: 'Pet Age',
            hint: 'Choose pet age',
            icon: Icons.cake_outlined,
            value: pet.age,
            onTap: onAgeTap,
          ),

          const SizedBox(height: 17),

          // ====================================================
          // BREED
          // ====================================================

          ProfileSelectionField(
            label: 'Breed',
            hint: 'Choose breed',
            icon: Icons.pets_outlined,
            value: pet.breed,
            onTap: onBreedTap,
          ),

          const SizedBox(height: 17),

          // ====================================================
          // BEHAVIOUR
          // ====================================================

          ProfileSelectionField(
            label: 'Behaviour',
            hint: 'Choose behaviour',
            icon: Icons.favorite_border_rounded,
            value: pet.behaviour,
            onTap: onBehaviourTap,
          ),
        ],
      ),
    );
  }
}
