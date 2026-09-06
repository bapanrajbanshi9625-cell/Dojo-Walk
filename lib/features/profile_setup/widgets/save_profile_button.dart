import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class SaveProfileButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const SaveProfileButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DojoWalkColors.primary,
          foregroundColor: DojoWalkColors.white,
          disabledBackgroundColor:
              DojoWalkColors.primary.withValues(
            alpha: 0.55,
          ),
          disabledForegroundColor: DojoWalkColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: DojoWalkColors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Save & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
