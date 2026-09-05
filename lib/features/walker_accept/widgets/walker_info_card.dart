import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WalkerInfoCard extends StatelessWidget {
  const WalkerInfoCard({
    super.key,
    required this.walkerName,
    this.profileImageUrl,
    this.rating,
    this.walkerPhone,
    this.distanceLabel = '--',
    this.etaLabel = '--',
    this.statusText = 'Walker is on the way',
  });

  final String walkerName;
  final String? profileImageUrl;
  final double? rating;
  final String? walkerPhone;

  final String distanceLabel;
  final String etaLabel;
  final String statusText;

  Future<void> _callWalker(BuildContext context) async {
    final phone = walkerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walker phone number is not available'),
        ),
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = walkerName.trim().isEmpty
        ? 'Your Walker'
        : walkerName.trim();

    final imageUrl = profileImageUrl?.trim() ?? '';

    final phone = walkerPhone?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, -5),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // DRAG HANDLE
          // ====================================================

          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          // ====================================================
          // STATUS
          // ====================================================

          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LIVE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // WALKER PROFILE
          // ====================================================

          Row(
            children: [
              _WalkerAvatar(
                imageUrl: imageUrl,
                size: 62,
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating != null
                              ? rating!.toStringAsFixed(1)
                              : '--',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Walker',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // PHONE NUMBER
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            phone.isEmpty ? '--' : phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ==================================================
              // CALL BUTTON
              // ==================================================

              Material(
                color: colors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: phone.isEmpty
                      ? null
                      : () => _callWalker(context),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.call_rounded,
                      color: phone.isEmpty
                          ? colors.onSurfaceVariant
                          : colors.onPrimary,
                      size: 23,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ====================================================
          // DISTANCE + ETA
          // ====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoValue(
                    icon: Icons.route_rounded,
                    value: distanceLabel,
                    label: 'Distance',
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: colors.outlineVariant,
                ),
                Expanded(
                  child: _InfoValue(
                    icon: Icons.schedule_rounded,
                    value: etaLabel,
                    label: 'Estimated arrival',
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

// ============================================================
// WALKER AVATAR
// ============================================================

class _WalkerAvatar extends StatelessWidget {
  const _WalkerAvatar({
    required this.imageUrl,
    required this.size,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _fallback(context),
              )
            : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.48,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

// ============================================================
// INFO VALUE
// ============================================================

class _InfoValue extends StatelessWidget {
  const _InfoValue({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: colors.primary,
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

"pubspec.yaml"

Agar "url_launcher" already nahi hai, dependency add karo:

dependencies:
  url_launcher: ^6.3.2

Phir GitHub Actions/build mein "flutter pub get" ho jayega.

Card ko call karte waqt

Jahan "WalkerInfoCard" call ho raha hai, wahan:

WalkerInfoCard(
  walkerName: walkerName,
  profileImageUrl: walkerProfileImage,
  rating: walkerRating,
  walkerPhone: walkerPhone,
  distanceLabel: distanceLabel,
  etaLabel: etaLabel,
  statusText: 'Walker is on the way',
)

Important: "walkerPhone" mein Firestore se Walker ka actual phone number pass hona chahiye.

Call button दबाने पर app direct call नहीं करेगा—Android ka phone dialer Walker ke number ke saath open hoga, jahan user call button press karega.
