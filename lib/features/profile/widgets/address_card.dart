import 'package:flutter/material.dart';

class AddressCard extends StatelessWidget {
  final String flatHouseNo;
  final String streetRoad;
  final String landmark;
  final bool isConnecting;
  final VoidCallback onConnectLocation;

  const AddressCard({
    super.key,
    required this.flatHouseNo,
    required this.streetRoad,
    required this.landmark,
    required this.isConnecting,
    required this.onConnectLocation,
  });

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);

  @override
  Widget build(BuildContext context) {
    final bool hasAddress =
        flatHouseNo.trim().isNotEmpty ||
        streetRoad.trim().isNotEmpty ||
        landmark.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAddress)
            const Text(
              'No address added yet.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            if (flatHouseNo.trim().isNotEmpty)
              _AddressRow(
                icon: Icons.home_outlined,
                label: 'Flat / House No.',
                value: flatHouseNo,
              ),

            if (streetRoad.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _AddressRow(
                icon: Icons.signpost_outlined,
                label: 'Street / Road',
                value: streetRoad,
              ),
            ],

            if (landmark.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _AddressRow(
                icon: Icons.place_outlined,
                label: 'Landmark',
                value: landmark,
              ),
            ],
          ],

          const SizedBox(height: 15),

          // ========================================================
          // LOCATION STATUS
          // ========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: orange,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location dena mandatory hai.',
                    style: TextStyle(
                      color: navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ========================================================
          // CONNECT CURRENT LOCATION
          // ========================================================

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed:
                  isConnecting ? null : onConnectLocation,
              style: OutlinedButton.styleFrom(
                foregroundColor: orange,
                disabledForegroundColor:
                    orange.withValues(alpha: 0.55),
                side: const BorderSide(
                  color: orange,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isConnecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: orange,
                      ),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      size: 19,
                    ),
              label: Text(
                isConnecting
                    ? 'Connecting...'
                    : 'Connect Current Location',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ADDRESS ROW
// ================================================================

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: orange,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
