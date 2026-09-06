// File:
// lib/features/insta_walk/widgets/insta_walk_view.dart

part of '../controllers/insta_walk_container.dart';

extension _InstaWalkView on _InstaWalkContainerState {
  // ============================================================
  // COMPACT PATTI
  // ============================================================

  Widget _buildCompactPatti() {
    final bool searching = _searching;

    final Widget patti = Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
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
            alpha: 0.20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ----------------------------------------------------
          // ICON
          // ----------------------------------------------------

          AnimatedBuilder(
            animation: _searchAnimationController,
            builder: (
              BuildContext context,
              Widget? child,
            ) {
              if (!searching) {
                return child!;
              }

              return Transform.translate(
                offset: Offset(
                  0,
                  _searchMovement.value.dy * 10,
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
            child: Container(
              width: 36,
              height: 36,
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
                searching
                    ? Icons.search_rounded
                    : Icons.flash_on_rounded,
                color: AppColors.mintTint,
                size: 19,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ----------------------------------------------------
          // TEXT
          // ----------------------------------------------------

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insta Walk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  searching
                      ? 'Searching for a nearby walker...'
                      : 'Find a nearby walker',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(
                      alpha: 0.70,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          // ----------------------------------------------------
          // STATUS
          // ----------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              searching ? 'LIVE' : 'ACTIVE',
              style: const TextStyle(
                color: AppColors.mintTint,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 2),

          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.white.withValues(
              alpha: 0.70,
            ),
            size: 21,
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return patti;
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: patti,
    );
  }

  // ============================================================
  // FULL SCREEN
  // ============================================================
  //
  // Kept for compatibility with existing callers.
  // Final visual is still compact.
  //

  Widget _buildFullScreen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        6,
        8,
        12,
      ),
      child: _buildCompactMainCard(),
    );
  }

  // ============================================================
  // MAIN CARD
  // ============================================================

  Widget _buildCompactMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
        height: 64,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
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
  // IDLE
  // ============================================================

  Widget _buildIdleCompact() {
    return Row(
      children: [
        // ------------------------------------------------------
        // ICON
        // ------------------------------------------------------

        Container(
          width: 38,
          height: 38,
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
          child: const Icon(
            Icons.flash_on_rounded,
            color: AppColors.mintTint,
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        // ------------------------------------------------------
        // TEXT
        // ------------------------------------------------------

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insta Walk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Find a nearby walker',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ------------------------------------------------------
        // START BUTTON
        // ------------------------------------------------------

        SizedBox(
          height: 38,
          child: InstaWalkSearchButton(
            loading: _checkingAddress,
            text: _checkingAddress
                ? 'Checking...'
                : 'Start',
            onPressed:
                _checkingAddress ? null : _findWalker,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCHING
  // ============================================================

  Widget _buildSearchingCompact() {
    return Row(
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
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.mint.withValues(
                  alpha: 0.24,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mint.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.mintTint,
              size: 21,
            ),
          ),
        ),

        const SizedBox(width: 11),

        // ------------------------------------------------------
        // SEARCH TEXT
        // ------------------------------------------------------

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insta Walk',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Searching for a nearby walker...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(
                    alpha: 0.70,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

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
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(
              alpha: 0.14,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: AppColors.mintTint,
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No walker found',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Try searching again',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(
                    alpha: 0.65,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          height: 36,
          child: InstaWalkSearchButton(
            loading: false,
            text: 'Try Again',
            onPressed: _retrySearch,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STOP SEARCH BUTTON
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
          disabledForegroundColor:
              AppColors.white.withValues(
            alpha: 0.70,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          side: BorderSide(
            color: AppColors.error.withValues(
              alpha: 0.40,
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
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stop_circle_outlined,
                    size: 17,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 5),
                  const Text(
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
  // OLD HEADER COMPATIBILITY
  // ============================================================

  Widget _header() {
    final bool isLive = _searching;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.mint,
                AppColors.mintTint,
              ],
            ),
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 9,
              ),
            ],
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: AppColors.navy,
            size: 22,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Insta Walk',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLive
                    ? 'Finding a walker for $_petName'
                    : 'Find an available walker nearby',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white.withValues(
                    alpha: 0.60,
                  ),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 7),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.mint.withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isLive ? 'LIVE' : 'ACTIVE',
                style: const TextStyle(
                  color: AppColors.mintTint,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
