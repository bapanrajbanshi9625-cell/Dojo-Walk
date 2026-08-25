import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/insta_walk_search_service.dart';
import '../services/insta_walk_request_state.dart';
import '../services/insta_walk_search_result.dart';

class InstaWalkContainer extends StatefulWidget {
  const InstaWalkContainer({
    super.key,
  });

  @override
  State<InstaWalkContainer> createState() =>
      _InstaWalkContainerState();
}

class _InstaWalkContainerState
    extends State<InstaWalkContainer> {

  // ==========================================================
  // SERVICES
  // ==========================================================

  late final InstaWalkSearchService _service;

  // ==========================================================
  // STATE
  // ==========================================================

  StreamSubscription<InstaWalkRequestState>?
      _requestSubscription;

  InstaWalkRequestState?
      _requestState;

  bool _loading = false;

  String? _requestId;

  String _ownerId = '';

  String _ownerName = 'Dog Owner';

  String _address = '';

  GeoPoint? _ownerLocation;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _service = InstaWalkSearchService();

    _restoreActiveRequest();
  }

  // ==========================================================
  // FIND OWNER PROFILE
  // ==========================================================

  Future<void> _loadOwnerProfile() async {

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {

      final DocumentSnapshot<
          Map<String, dynamic>>?
          document =
          await _service.findOwnerProfile();

      if (document == null ||
          !document.exists) {
        return;
      }

      final Map<String, dynamic> data =
          document.data() ??
              <String, dynamic>{};

      final String ownerId =
          (data['ownerId'] ??
                  data['id'] ??
                  document.id)
              .toString()
              .trim();

      final String ownerName =
          (data['ownerName'] ??
                  data['name'] ??
                  'Dog Owner')
              .toString()
              .trim();

      final String address =
          (data['address'] ??
                  data['Adress'] ??
                  '')
              .toString()
              .trim();

      final dynamic location =
          data['location'] ??
          data['ownerLocation'];

      GeoPoint? ownerLocation;

      if (location is GeoPoint) {
        ownerLocation = location;
      }

      if (!mounted) {
        return;
      }

      setState(() {

        _ownerId =
            ownerId.isNotEmpty
                ? ownerId
                : user.uid;

        _ownerName =
            ownerName.isNotEmpty
                ? ownerName
                : 'Dog Owner';

        _address =
            address;

        _ownerLocation =
            ownerLocation;
      });

    } on FirebaseException catch (e) {

      debugPrint(
        'Owner profile Firebase error: '
        '${e.code} - ${e.message}',
      );

    } catch (e) {

      debugPrint(
        'Owner profile error: $e',
      );
    }
  }

  // ==========================================================
  // RESTORE ACTIVE REQUEST
  // ==========================================================

  Future<void> _restoreActiveRequest() async {

    await _loadOwnerProfile();

    if (!mounted) {
      return;
    }

    if (_ownerId.isEmpty) {
      return;
    }

    try {

      final InstaWalkRequestState?
          state =
          await _service.findActiveRequest(
        ownerId: _ownerId,
      );

      if (!mounted) {
        return;
      }

      if (state == null) {
        return;
      }

      _requestId =
          state.requestId;

      _requestState =
          state;

      setState(() {});

      _listenToRequest(
        state.requestId,
      );

    } on FirebaseException catch (e) {

      debugPrint(
        'Restore request Firebase error: '
        '${e.code} - ${e.message}',
      );

    } catch (e) {

      debugPrint(
        'Restore request error: $e',
      );
    }
  }

  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<void> _startSearch() async {

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {

      await _loadOwnerProfile();

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage(
          'Please login first.',
        );
        return;
      }

      // --------------------------------------------------------
      // OWNER ID FALLBACK
      // --------------------------------------------------------

      if (_ownerId.isEmpty) {
        _ownerId = user.uid;
      }

      // --------------------------------------------------------
      // ADDRESS REQUIRED
      // --------------------------------------------------------

      if (_address.trim().isEmpty) {

        _showMessage(
          'Owner address is missing.',
        );

        return;
      }

      // --------------------------------------------------------
      // LOCATION REQUIRED
      // --------------------------------------------------------

      if (_ownerLocation == null) {

        _showMessage(
          'Owner location is missing.',
        );

        return;
      }

      // --------------------------------------------------------
      // CREATE FIRESTORE REQUEST
      // --------------------------------------------------------

      final InstaWalkSearchResult result =
          await _service.startSearch(

        ownerId:
            _ownerId,

        ownerName:
            _ownerName,

        address:
            _address,

        ownerLocation:
            _ownerLocation!,
      );

      if (!mounted) {
        return;
      }

      if (!result.success) {

        _showMessage(
          result.message ??
              'Unable to start Insta Walk search.',
        );

        return;
      }

      final String? requestId =
          result.requestId;

      if (requestId == null ||
          requestId.trim().isEmpty) {

        _showMessage(
          'Request ID was not created.',
        );

        return;
      }

      _requestId =
          requestId;

      _listenToRequest(
        requestId,
      );

      _showMessage(
        'Searching for a nearby walker...',
      );

      setState(() {});

    } on FirebaseException catch (e) {

      _showMessage(
        e.message ??
            'Firestore error.',
      );

    } catch (e) {

      debugPrint(
        'Start search error: $e',
      );

      _showMessage(
        'Unable to start search.',
      );

    } finally {

      if (mounted) {

        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================
  // LISTEN TO REQUEST
  // ==========================================================

  void _listenToRequest(
    String requestId,
  ) {

    _requestSubscription?.cancel();

    _requestSubscription =
        _service
            .listenForRequest(
              requestId,
            )
            .listen(
      (
        InstaWalkRequestState state,
      ) {

        if (!mounted) {
          return;
        }

        setState(() {

          _requestState =
              state;

          _requestId =
              state.requestId;
        });

        // ------------------------------------------------------
        // ACCEPTED
        // ------------------------------------------------------

        if (state.isAccepted) {

          _showMessage(
            'Walker accepted your request.',
          );

          return;
        }

        // ------------------------------------------------------
        // CANCELLED
        // ------------------------------------------------------

        if (state.isCancelled) {

          _showMessage(
            'Search cancelled.',
          );

          return;
        }

        // ------------------------------------------------------
        // EXPIRED
        // ------------------------------------------------------

        if (state.isExpired) {

          _showMessage(
            'Search expired.',
          );

          return;
        }
      },
      onError: (Object error) {

        debugPrint(
          'Request listener error: $error',
        );

        if (!mounted) {
          return;
        }

        _showMessage(
          'Unable to listen for request updates.',
        );
      },
    );
  }

  // ==========================================================
  // CANCEL SEARCH
  // ==========================================================

  Future<void> _cancelSearch() async {

    final String? requestId =
        _requestId;

    if (requestId == null ||
        requestId.trim().isEmpty) {
      return;
    }

    if (_loading) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {

      final bool success =
          await _service.cancelSearch(
        requestId:
            requestId,
      );

      if (!mounted) {
        return;
      }

      if (success) {

        _requestSubscription?.cancel();

        _requestSubscription =
            null;

        setState(() {

          _requestId =
              null;

          _requestState =
              null;
        });

        _showMessage(
          'Search cancelled.',
        );

      } else {

        _showMessage(
          'Unable to cancel search.',
        );
      }

    } catch (e) {

      debugPrint(
        'Cancel search error: $e',
      );

      if (mounted) {

        _showMessage(
          'Unable to cancel search.',
        );
      }

    } finally {

      if (mounted) {

        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message,
  ) {

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS TEXT
  // ==========================================================

  String _statusText() {

    final InstaWalkRequestState?
        state =
        _requestState;

    if (state == null) {
      return 'Ready to find a nearby walker';
    }

    if (state.isSearching) {
      return 'Searching for a nearby walker...';
    }

    if (state.isAccepted) {
      return 'Walker accepted your request';
    }

    if (state.isCancelled) {
      return 'Search cancelled';
    }

    if (state.isExpired) {
      return 'Search expired';
    }

    return 'Request not found';
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {

    final bool isSearching =
        _requestState?.isSearching ??
            false;

    final bool isAccepted =
        _requestState?.isAccepted ??
            false;

    return Card(
      margin:
          const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              children: [

                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(14),
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(
                              alpha: 0.10,
                            ),
                  ),
                  child: Icon(
                    Icons.pets,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Insta Walk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _statusText(),
                        style: TextStyle(
                          color:
                              Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // --------------------------------------------------
            // SEARCH STATUS
            // --------------------------------------------------

            if (isSearching) ...[

              const LinearProgressIndicator(),

              const SizedBox(
                height: 16,
              ),

              Text(
                'Looking for a walker within 3.5 km.',
                style: TextStyle(
                  color:
                      Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width:
                    double.infinity,
                child: OutlinedButton(
                  onPressed:
                      _loading
                          ? null
                          : _cancelSearch,
                  child: Text(
                    _loading
                        ? 'Please wait...'
                        : 'Stop Search',
                  ),
                ),
              ),

            ] else if (isAccepted) ...[

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(14),
                  color:
                      Colors.green.withValues(
                    alpha: 0.10,
                  ),
                ),
                child: const Row(
                  children: [

                    Icon(
                      Icons.check_circle,
                      color:
                          Colors.green,
                    ),

                    SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        'A walker has accepted your Insta Walk request.',
                      ),
                    ),
                  ],
                ),
              ),

            ] else ...[

              SizedBox(
                width:
                    double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _loading
                          ? null
                          : _startSearch,
                  icon: const Icon(
                    Icons.search,
                  ),
                  label: Text(
                    _loading
                        ? 'Starting...'
                        : 'Start Insta Walk Search',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {

    _requestSubscription?.cancel();

    _service.dispose();

    super.dispose();
  }
}
