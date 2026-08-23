// File: lib/widgets/generate_qr_button.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/qr_service.dart';

class GenerateQRButton extends StatefulWidget {
  final bool isLiveWalk;

  final VoidCallback? onLiveWalkTap;

  /// Walker successfully connected होने पर parent को notify करेगा.
  final void Function(QRScanState state)? onWalkerConnected;

  const GenerateQRButton({
    super.key,
    this.isLiveWalk = false,
    this.onLiveWalkTap,
    this.onWalkerConnected,
  });

  @override
  State<GenerateQRButton> createState() =>
      _GenerateQRButtonState();
}

class _GenerateQRButtonState extends State<GenerateQRButton> {
  StreamSubscription<QRScanState>? _scanSubscription;

  bool _opening = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    super.dispose();
  }

  // ==========================================================
  // OPEN / GENERATE OWNER QR
  // ==========================================================

  Future<void> _openQR() async {
    if (_opening) {
      return;
    }

    setState(() {
      _opening = true;
    });

    try {
      // --------------------------------------------------------
      // GENERATE QR
      // --------------------------------------------------------

      final QRData qr =
          await QRService.instance.createOwnerQR();

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // CANCEL OLD LISTENER
      // --------------------------------------------------------

      await _scanSubscription?.cancel();
      _scanSubscription = null;

      // --------------------------------------------------------
      // WATCH WALKER CONNECTION
      // --------------------------------------------------------

      _scanSubscription = QRService.instance
          .watchScan(qr.ownerId)
          .listen(
        (QRScanState state) {
          if (!mounted) {
            return;
          }

          // Only notify after actual connection.
          if (!state.connected) {
            return;
          }

          debugPrint(
            'QR Walker connected: '
            'walkerId=${state.walkerId}, '
            'walkerName=${state.walkerName}, '
            'walkId=${state.walkId}',
          );

          widget.onWalkerConnected?.call(state);
        },
        onError: (
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint(
            'QR scan listener error: $error',
          );
        },
      );

      // --------------------------------------------------------
      // OPEN QR BOTTOM SHEET
      // --------------------------------------------------------

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (_) {
          return OwnerQRBottomSheet(
            data: qr,
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      final String message = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Unable to generate QR code.'
                : message,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint(
        'Owner QR generation error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (widget.isLiveWalk) {
      return _liveWalkBar();
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _opening ? null : _openQR,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2E585E),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              // ==================================================
              // QR ICON
              // ==================================================

              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _opening
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E585E),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF2E585E),
                        size: 21,
                      ),
              ),

              const SizedBox(width: 10),

              // ==================================================
              // TEXT
              // ==================================================

              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Connect with your walker',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ARROW
              // ==================================================

              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: .12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE WALK BAR
  // ==========================================================

  Widget _liveWalkBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onLiveWalkTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B8F4D),
                    Color(0xFF126B39),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 14),
                  Icon(
                    Icons.directions_walk_rounded,
                    color: Colors.white,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Live Walk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OWNER QR BOTTOM SHEET
// ============================================================

class OwnerQRBottomSheet extends StatelessWidget {
  final QRData data;

  const OwnerQRBottomSheet({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          22,
          10,
          22,
          26,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // HANDLE
            // ==================================================

            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // TITLE
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan to Connect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // ==================================================
            // OWNER NAME
            // ==================================================

            Text(
              data.ownerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 4),

            // ==================================================
            // OWNER ID
            // ==================================================

            Text(
              'Owner ID: ${data.ownerId}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // QR CODE
            // ==================================================

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: .08,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: QrImageView(
                data: data.qrPayload,
                size: 215,
                version: QrVersions.auto,
                backgroundColor: Colors.white,
                errorCorrectionLevel:
                    QrErrorCorrectLevel.H,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Scan this QR with the Walker app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // WAITING STATUS
            // ==================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Waiting for Walker...',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // WALK ID
            // ==================================================

            Text(
              'Walk ID: ${data.walkId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
