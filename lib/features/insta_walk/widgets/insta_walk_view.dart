// File:
// lib/features/insta_walk/widgets/insta_walk_view.dart

part of '../controllers/insta_walk_container.dart';

// ============================================================
// INSTA WALK VIEW
// ============================================================
//
// OWNER-SIDE INSTA WALK UI
//
// NORMAL
//   ⚡ Insta Walk                 [ Start ]
//      Find a nearby walker
//
// SEARCHING
//   🔍 Insta Walk                 [ Stop ]
//      Searching for a nearby walker...
//
// FINISHED
//   ↻ No walker found             [ Try Again ]
//
// IMPORTANT:
// - No GPS here.
// - No map here.
// - No radar here.
// - Search lifecycle remains in controller/service.
// ============================================================

extension _InstaWalkView on _InstaWalkContainerState {
  // ============================================================
  // FULL SCREEN
  // ============================================================

  Widget _buildFullScreen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        0,
        0,
        0,
      ),
      child: _buildMainCard(),
    );
  }

  // ============================================================
  // MAIN CARD
  // ============================================================

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 82,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.deepTeal,
            AppColors.slate,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.mint.withValues(
            alpha: 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _buildMainContent(),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    // ----------------------------------------------------------
    // RECOVERY
    // ----------------------------------------------------------

    if (_recovering) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 21,
            height: 21,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.mint,
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // SEARCHING
    // ----------------------------------------------------------

    if (_searching) {
      return _buildSearchingCompact();
    }

    // ----------------------------------------------------------
    // FINISHED
    // ----------------------------------------------------------

    if (_searchFinished) {
      return _buildFinishedCompact();
    }

    // ----------------------------------------------------------
    // NORMAL
    // ----------------------------------------------------------

    return _buildIdleCompact();
  }

  // ============================================================
  // NORMAL / IDLE
  // ============================================================

  Widget _buildIdleCompact() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------------------------------------------------------
        // FLASH ICON
        // ------------------------------------------------------

        _buildIconCircle(
          icon: Icons.flash_on_rounded,
          iconColor: AppColors.mintTint,
        ),

        const SizedBox(width: 11),

        // ------------------------------------------------------
        // TEXT
        // ------------------------------------------------------

        const Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insta Walk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Find a nearby walker',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ------------------------------------------------------
        // START
        // ------------------------------------------------------

        _buildStartButton(),
      ],
    );
  }

  // ============================================================
  // START BUTTON
  // ============================================================

  Widget _buildStartButton() {
    final bool loading = _checkingAddress;

    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: loading ? null : _findWalker,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          disabledForegroundColor: AppColors.navy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.navy,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 17,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Start',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // SEARCHING
  // ============================================================

  Widget _buildSearchingCompact() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------------------------------------------------------
        // ANIMATED SEARCH ICON
        // ------------------------------------------------------

        AnimatedBuilder(
          animation: _searchAnimationController,
          builder: (
            BuildContext context,
            Widget? child,
          ) {
            return Transform.translate(
              offset: Offset(
                0,
                _searchMovement.value.dy * 8,
              ),
              child: Transform.rotate(
                angle: _searchRotation.value,
                child: Transform.scale(
                  scale: _searchScale.value,
                  child: child,
                ),
              ),
            );
          },
          child: _buildIconCircle(
            icon: Icons.search_rounded,
            iconColor: AppColors.mintTint,
            size: 40,
            iconSize: 21,
          ),
        ),

        const SizedBox(width: 11),

        // ------------------------------------------------------
        // SEARCH TEXT
        // ------------------------------------------------------

        const Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insta Walk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Searching for a nearby walker...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 9),

        // ------------------------------------------------------
        // STOP
        // ------------------------------------------------------

        _buildStopSearchButtonCompact(),
      ],
    );
  }

  // ============================================================
  // FINISHED
  // ============================================================

  Widget _buildFinishedCompact() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildIconCircle(
          icon: Icons.refresh_rounded,
          iconColor: AppColors.mintTint,
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No walker found',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Try searching again',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 9),

        _buildRetryButton(),
      ],
    );
  }

  // ============================================================
  // RETRY BUTTON
  // ============================================================

  Widget _buildRetryButton() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _retrySearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Try Again',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STOP BUTTON
  // ============================================================

  Widget _buildStopSearchButtonCompact() {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _stopping ? null : _stopSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          side: BorderSide(
            color: AppColors.error.withValues(
              alpha: 0.45,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: _stopping
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mintTint,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stop_circle_outlined,
                    size: 17,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Stop',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // ICON CIRCLE
  // ============================================================

  Widget _buildIconCircle({
    required IconData icon,
    required Color iconColor,
    double size = 38,
    double iconSize = 20,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(
          alpha: 0.14,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.mint.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}
