// File:
// lib/features/insta_walk/widgets/insta_walk_view.dart

part of '../controllers/insta_walk_container.dart';

extension _InstaWalkView on _InstaWalkContainerState {
  // ============================================================
  // COMPACT PATTI
  // ============================================================

  Widget _buildCompactPatti() {
    final bool accepted =
        _acceptedNavigationStarted;

    final Widget patti = Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.deepTeal,
            AppColors.slate,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius:
            BorderRadius.circular(17),
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
          Container(
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
              accepted
                  ? Icons.check_circle_rounded
                  : Icons.flash_on_rounded,
              color: AppColors.mintTint,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insta Walk',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  accepted
                      ? 'Walker accepted'
                      : _searching
                          ? 'Finding walker for $_petName'
                          : 'Walker is active',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        AppColors.white
                            .withValues(
                      alpha: 0.70,
                    ),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  AppColors.mint.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              accepted
                  ? 'ACCEPTED'
                  : _searching
                      ? 'LIVE'
                      : 'ACTIVE',
              style: TextStyle(
                color:
                    AppColors.mintTint,
                fontSize: 7,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 2),

          Icon(
            Icons.chevron_right_rounded,
            color:
                AppColors.white.withValues(
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
      behavior:
          HitTestBehavior.opaque,
      child: patti,
    );
  }

  // ============================================================
  // FULL SCREEN
  // ============================================================

  Widget _buildFullScreen() {
    // ==========================================================
    // ACCEPTED = REMOVE COMPLETE INSTA WALK CONTAINER
    // ==========================================================
    //
    // Accept होते ही:
    //
    // - complete card disappears
    // - radar already stopped
    // - Firestore listener already stopped
    // - no empty teal container remains
    //
    // Active Walk Strip is handled externally.
    //

    if (_acceptedNavigationStarted) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        8,
        6,
        8,
        20,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.navy,
              AppColors.deepTeal,
              AppColors.slate,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(21),
          border: Border.all(
            color:
                AppColors.mint.withValues(
              alpha: 0.18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppColors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 16,
              offset:
                  const Offset(0, 6),
            ),
          ],
        ),
        child:
            _buildFullScreenContent(),
      ),
    );
  }

  // ============================================================
  // FULL SCREEN CONTENT
  // ============================================================

  Widget _buildFullScreenContent() {
    // ==========================================================
    // ACCEPTED GUARD
    // ==========================================================

    if (_acceptedNavigationStarted) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // RECOVERY
    // ==========================================================

    if (_recovering) {
      return const SizedBox(
        height: 150,
        child: Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.mint,
          ),
        ),
      );
    }

    // ==========================================================
    // NORMAL CONTENT
    // ==========================================================

    return Column(
      mainAxisSize:
          MainAxisSize.min,
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _header(),

        const SizedBox(height: 10),

        Text(
          _searching
              ? 'Searching available walkers near your current location.'
              : 'Find an available walker nearby instantly.',
          style: TextStyle(
            color:
                AppColors.white.withValues(
              alpha: 0.70,
            ),
            fontSize: 12,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // IDLE
        // ======================================================

        if (!_searching &&
            !_searchFinished &&
            !_acceptedNavigationStarted)
          InstaWalkSearchButton(
            loading:
                _checkingAddress,
            text: _checkingAddress
                ? 'Checking location...'
                : 'Find a Walker Now',
            onPressed:
                _checkingAddress
                    ? null
                    : _findWalker,
          ),

        // ======================================================
        // SEARCHING
        // ======================================================

        if (_searching &&
            !_acceptedNavigationStarted)
          _buildSearching(),

        // ======================================================
        // SEARCH FINISHED
        // ======================================================

        if (!_searching &&
            !_acceptedNavigationStarted &&
            _searchFinished)
          InstaWalkSearchButton(
            loading: false,
            text: 'Try Again',
            onPressed:
                _retrySearch,
          ),
      ],
    );
  }

  // ============================================================
  // SEARCHING UI
  // ============================================================

  Widget _buildSearching() {
    if (_acceptedNavigationStarted) {
      return const SizedBox.shrink();
    }

    if (_ownerPosition != null) {
      return Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          InstaWalkSearching(
            map: InstaWalkMapRadar(
              ownerPoint: LatLng(
                _ownerPosition!
                    .latitude,
                _ownerPosition!
                    .longitude,
              ),
              searchRadiusKm:
                  InstaWalkSearchService
                      .searchRadiusKm,
              radarAnimation:
                  _radarController,
            ),
          ),

          const SizedBox(height: 9),

          _buildStopSearchButton(),
        ],
      );
    }

    return Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                AppColors.black
                    .withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                      AppColors.mint,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Searching nearby walkers',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppColors.white,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Searching',
                style: TextStyle(
                  color:
                      AppColors.mintTint,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 9),

        _buildStopSearchButton(),
      ],
    );
  }

  // ============================================================
  // STOP SEARCH BUTTON
  // ============================================================

  Widget _buildStopSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed:
            _stopping
                ? null
                : _stopSearch,
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.navy,
          disabledBackgroundColor:
              AppColors.navy,
          foregroundColor:
              AppColors.white,
          disabledForegroundColor:
              AppColors.white
                  .withValues(
            alpha: 0.70,
          ),
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          side: BorderSide(
            color:
                AppColors.error
                    .withValues(
              alpha: 0.40,
            ),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
        ),
        child: _stopping
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color:
                      AppColors.mintTint,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Icon(
                    Icons
                        .stop_circle_outlined,
                    size: 20,
                    color:
                        AppColors.error,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  const Text(
                    'Stop Search',
                    style:
                        TextStyle(
                      color:
                          AppColors.white,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    final bool isLive =
        _searching &&
        !_acceptedNavigationStarted;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration:
              BoxDecoration(
            gradient:
                LinearGradient(
              colors: [
                AppColors.mint,
                AppColors.mintTint,
              ],
            ),
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.mint
                        .withValues(
                  alpha: 0.20,
                ),
                blurRadius: 9,
              ),
            ],
          ),
          child: Icon(
            _acceptedNavigationStarted
                ? Icons
                    .check_circle_rounded
                : Icons
                    .flash_on_rounded,
            color:
                AppColors.navy,
            size: 25,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'Insta Walk',
                style: TextStyle(
                  color:
                      AppColors.white,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                _acceptedNavigationStarted
                    ? 'Walker accepted'
                    : isLive
                        ? 'Finding a walker for $_petName'
                        : 'Walker is active',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      AppColors.white
                          .withValues(
                    alpha: 0.60,
                  ),
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 7),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.mint
                    .withValues(
              alpha: 0.12,
            ),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color:
                  AppColors.mint
                      .withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.mint,
                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                _acceptedNavigationStarted
                    ? 'ACCEPTED'
                    : isLive
                        ? 'LIVE'
                        : 'ACTIVE',
                style:
                    const TextStyle(
                  color:
                      AppColors.mintTint,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
