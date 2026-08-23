part of 'insta_walk_container.dart';

extension _InstaWalkView on _InstaWalkContainerState {
  // ============================================================
  // COMPACT PATTI
  // ============================================================

  Widget _buildCompactPatti() {
    final Widget patti = Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF243746),
            Color(0xFF304E5A),
            Color(0xFF376A70),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF65D6C8).withValues(
            alpha: 0.20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
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

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF65D6C8).withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF65D6C8).withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Color(0xFF8FFFEF),
              size: 19,
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
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _searching
                      ? 'Finding walker for $_petName'
                      : 'Walker is active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
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
              color: const Color(0xFF65D6C8).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _searching ? 'LIVE' : 'ACTIVE',
              style: const TextStyle(
                color: Color(0xFF8FFFEF),
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 2),

          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
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

  Widget _buildFullScreen() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        15,
        6,
        15,
        12,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF243746),
              Color(0xFF304E5A),
              Color(0xFF376A70),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: const Color(0xFF65D6C8).withValues(
              alpha: 0.18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _buildFullScreenContent(),
      ),
    );
  }

  // ============================================================
  // FULL SCREEN CONTENT
  // ============================================================

  Widget _buildFullScreenContent() {
    if (_recovering) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF65D6C8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),

        const SizedBox(height: 10),

        Text(
          _searching
              ? 'Searching available walkers near your current location.'
              : 'Find an available walker nearby instantly.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 12),

        // ======================================================
        // FIND WALKER BUTTON
        // ======================================================

        if (!_searching && !_searchFinished)
          InstaWalkSearchButton(
            loading: _checkingAddress,
            text: _checkingAddress
                ? 'Checking location...'
                : 'Find a Walker Now',
            onPressed: _checkingAddress
                ? null
                : _findWalker,
          ),

        // ======================================================
        // SEARCHING
        // ======================================================

        if (_searching) _buildSearching(),

        // ======================================================
        // RETRY
        // ======================================================

        if (_searchFinished)
          InstaWalkRetry(
            onRetry: _retrySearch,
          ),
      ],
    );
  }

  // ============================================================
  // SEARCHING UI
  // ============================================================

  Widget _buildSearching() {
    if (_ownerPosition != null) {
      return Column(
        children: [
          InstaWalkSearching(
            map: InstaWalkMapRadar(
              ownerPoint: LatLng(
                _ownerPosition!.latitude,
                _ownerPosition!.longitude,
              ),
              searchRadiusKm:
                  InstaWalkSearchService.searchRadiusKm,
              radarAnimation: _radarController,
            ),
          ),

          const SizedBox(height: 9),

          _buildStopSearchButton(),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Column(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF65D6C8),
                ),
              ),

              SizedBox(height: 10),

              Text(
                'Searching nearby walkers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Searching',
                style: TextStyle(
                  color: Color(0xFF8FFFEF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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
        onPressed: _stopping ? null : _stopSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF243746),
          disabledBackgroundColor: const Color(0xFF243746),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          side: BorderSide(
            color: const Color(0xFFFF8A80).withValues(
              alpha: 0.40,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: _stopping
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Color(0xFF8FFFEF),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stop_circle_outlined,
                    size: 20,
                    color: Color(0xFFFF8A80),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Stop Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
    final bool isLive = _searching;

    return Row(
      children: [
        // ------------------------------------------------------
        // ICON
        // ------------------------------------------------------

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF65D6C8),
                Color(0xFF8FFFEF),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF65D6C8).withValues(
                  alpha: 0.20,
                ),
                blurRadius: 9,
              ),
            ],
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: Color(0xFF243746),
            size: 25,
          ),
        ),

        const SizedBox(width: 11),

        // ------------------------------------------------------
        // TITLE
        // ------------------------------------------------------

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Insta Walk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                isLive
                    ? 'Finding a walker for $_petName'
                    : 'Walker is active',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 7),

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF65D6C8).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF65D6C8).withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF65D6C8),
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                isLive ? 'LIVE' : 'ACTIVE',
                style: const TextStyle(
                  color: Color(0xFF8FFFEF),
                  fontSize: 8,
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
