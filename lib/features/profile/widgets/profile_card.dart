import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walk_design_system.dart';

class ProfileCard extends StatelessWidget {
  final String ownerName;
  final String profileImageUrl;
  final bool uploadingProfilePhoto;
  final VoidCallback onChangePhoto;

  const ProfileCard({
    super.key,
    required this.ownerName,
    required this.profileImageUrl,
    required this.uploadingProfilePhoto,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto =
        profileImageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: DojoWalkColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoWalkColors.primary.withValues(
            alpha: 0.10,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkColors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ======================================================
          // PROFILE PHOTO
          // ======================================================

          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DojoWalkColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  border: Border.all(
                    color: DojoWalkColors.primary.withValues(
                      alpha: 0.20,
                    ),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          profileImageUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Icon(
                              Icons.person_rounded,
                              color: DojoWalkColors.primary,
                              size: 30,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: DojoWalkColors.primary,
                          size: 30,
                        ),
                ),
              ),

              // ==================================================
              // CAMERA BUTTON
              // ==================================================

              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: DojoWalkColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: uploadingProfilePhoto
                        ? null
                        : onChangePhoto,
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: uploadingProfilePhoto
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DojoWalkColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: DojoWalkColors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 13),

          // ======================================================
          // OWNER INFORMATION
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Owner Profile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: DojoWalkColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  ownerName.trim().isEmpty
                      ? 'Owner'
                      : ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DojoWalkColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  hasPhoto
                      ? 'Profile photo'
                      : 'Add your profile photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DojoWalkColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // CHANGE / UPLOAD
          // ======================================================

          TextButton(
            onPressed: uploadingProfilePhoto
                ? null
                : onChangePhoto,
            style: TextButton.styleFrom(
              foregroundColor: DojoWalkColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              minimumSize: Size.zero,
              tapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              hasPhoto ? 'Change' : 'Upload',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
