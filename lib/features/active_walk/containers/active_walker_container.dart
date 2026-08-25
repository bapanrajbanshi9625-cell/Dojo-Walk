import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/active_walk.dart';
import '../models/active_walk_mapper.dart';

class ActiveWalkerContainer extends StatelessWidget {
  ActiveWalkerContainer({
    super.key,
  });

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color border = Color(0xFFD6DAE0);

  static const Color primary = AppColors.primary;

  static const Color callColor = Color(0xFF16A34A);
  static const Color smsColor = Color(0xFF238EAE);
  static const Color cancelColor = Color(0xFFDC2626);

  // ==========================================================
  // SERVICE
  // ==========================================================

  final ActiveWalkService _service =
      ActiveWalkService.instance;

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ownerProfiles')
          .doc(user.uid)
          .snapshots(),
      builder: (
        context,
        ownerSnapshot,
      ) {
        if (ownerSnapshot.connectionState ==
            ConnectionState.waiting) {
          return _loading();
        }

        if (ownerSnapshot.hasError) {
          return _error(
            'Unable to load owner profile.',
          );
        }

        final Map<String, dynamic>? ownerData =
            ownerSnapshot.data?.data();

        if (ownerData == null) {
          return const SizedBox.shrink();
        }

        final String ownerId = _readString(
          ownerData,
          const [
            'ownerId',
            'businessId',
            'Owner ID',
            'Business ID',
          ],
        );

        if (ownerId.isEmpty) {
          return const SizedBox.shrink();
        }

        // ====================================================
        // ACTIVE WALK
        // ====================================================

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchActiveWalks(
            ownerId: ownerId,
          ),
          builder: (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _loading();
            }

            if (snapshot.hasError) {
              return _error(
                'Unable to load active walker.',
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document =
                snapshot.data!.docs.first;

            final Map<String, dynamic> data =
                document.data();

            final ActiveWalk activeWalk =
                ActiveWalkMapper.fromMap(
              document.id,
              data,
            );

            if (activeWalk.walkerId.isEmpty) {
              return _error(
                'Walker ID is missing.',
              );
            }

            return _buildCard(
              context,
              activeWalk,
              data,
              document.id,
              ownerId,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _buildCard(
    BuildContext context,
    ActiveWalk activeWalk,
    Map<String, dynamic> data,
    String activeWalkDocumentId,
    String ownerId,
  ) {
    final String dogName = _readString(
      data,
      const [
        'petName',
        'dogName',
        'Pet Name',
        'Dog Name',
      ],
      fallback: activeWalk.petName.isNotEmpty
          ? activeWalk.petName
          : 'Your Pet',
    );

    final String dogBreed = _readString(
      data,
      const [
        'petBreed',
        'dogBreed',
        'Pet Breed',
        'Dog Breed',
        'breed',
      ],
      fallback: 'Breed not available',
    );

    final String address = _readString(
      data,
      const [
        'address',
        'Adress',
        'Address',
      ],
      fallback: 'Address not available',
    );

    // ========================================================
    // IMPORTANT
    //
    // ActiveWalk अब requestId रखता है।
    // ========================================================

    final GeoPoint? ownerLocation =
        _readGeoPoint(
      data,
      const [
        'destinationLocation',
        'ownerLocation',
        'location',
        'ownerGeoPoint',
      ],
    );

    final String walkerPhone =
        activeWalk.walkerPhone.trim();

    final String status =
        _readString(
      data,
      const ['status'],
      fallback: 'On that way',
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withOpacity(.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================

          Row(
            children: [
              _profileIcon(55),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      activeWalk.walkerName.isNotEmpty
                          ? activeWalk.walkerName
                          : 'Walker',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Walker ID: ${activeWalk.walkerId}',
                      style: const TextStyle(
                        color: slate,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEAF7EF),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'Started'
                      ? 'WALKING'
                      : status == 'Reached'
                          ? 'REACHED'
                          : 'ACCEPTED',
                  style: const TextStyle(
                    color: callColor,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ==================================================
          // DOG
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F8F9),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        primary.withOpacity(.09),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: primary,
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
                        'YOUR DOG',
                        style: TextStyle(
                          color: slate,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        dogName,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        dogBreed,
                        style: const TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // ADDRESS
          // ==================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F8F9),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: primary,
                  size: 21,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PICKUP ADDRESS',
                        style: TextStyle(
                          color: slate,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        address,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // MAP
          // ==================================================

          if (ownerLocation != null)
            _buildOsmMap(ownerLocation),

          if (ownerLocation != null)
            const SizedBox(height: 10),

          // ==================================================
          // ACTIONS
          // ==================================================

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: callColor,
                  onTap: () {
                    _callWalker(
                      walkerPhone,
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _actionButton(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: smsColor,
                  onTap: () {
                    _smsWalker(
                      walkerPhone,
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _actionButton(
                  icon:
                      Icons.navigation_rounded,
                  label: 'Navigate',
                  color: primary,
                  onTap: () {
                    _openNavigation(
                      ownerLocation,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          // ==================================================
          // CANCEL
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                _confirmCancel(
                  context,
                  activeWalkDocumentId,
                  ownerId,
                  activeWalk,
                );
              },
              icon: const Icon(
                Icons.cancel_outlined,
                size: 19,
              ),
              label: const Text(
                'Cancel Walk',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    cancelColor,
                side: BorderSide(
                  color: cancelColor
                      .withOpacity(.25),
                ),
                backgroundColor:
                    cancelColor.withOpacity(
                  .035,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Walker accepted your Insta Walk request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: slate,
                fontSize: 10,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OSM MAP
  // ==========================================================

  Widget _buildOsmMap(
    GeoPoint location,
  ) {
    final LatLng point = LatLng(
      location.latitude,
      location.longitude,
    );

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 210,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            interactionOptions:
                const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 52,
                  height: 52,
                  child: Container(
                    decoration:
                        BoxDecoration(
                      color: primary,
                      shape:
                          BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(.20),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_rounded,
                      color: primary,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Pickup location',
                      style: TextStyle(
                        color: navy,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE ICON
  // ==========================================================

  Widget _profileIcon(
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withOpacity(.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: primary,
        size: size * .52,
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              color.withOpacity(.055),
          side: BorderSide(
            color:
                color.withOpacity(.18),
          ),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CANCEL CONFIRMATION
  // ==========================================================

  Future<void> _confirmCancel(
    BuildContext context,
    String activeWalkDocumentId,
    String ownerId,
    ActiveWalk activeWalk,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Cancel Walk?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this walk?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    cancelColor,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Cancel Walk'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _cancelWalk(
      context: context,
      activeWalkDocumentId:
          activeWalkDocumentId,
      ownerId: ownerId,
      activeWalk: activeWalk,
    );
  }

  // ==========================================================
  // CANCEL WALK
  // ==========================================================

  Future<void> _cancelWalk({
    required BuildContext context,
    required String activeWalkDocumentId,
    required String ownerId,
    required ActiveWalk activeWalk,
  }) async {
    try {
      final FirebaseAuth auth =
          FirebaseAuth.instance;

      final String? uid =
          auth.currentUser?.uid;

      // ======================================================
      // ACTIVE WALK
      // ======================================================

      await FirebaseFirestore.instance
          .collection('active_walk')
          .doc(activeWalkDocumentId)
          .set(
        <String, dynamic>{
          'status': 'cancelled',
          'cancelledBy': 'owner',
          'cancelledByUid': uid,
          'cancelledAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ======================================================
      // REQUEST
      //
      // IMPORTANT:
      // ActiveWalk.requestId से original request मिलेगा.
      // ======================================================

      final String requestId =
          _readActiveWalkRequestId(
        activeWalk,
      );

      if (requestId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('walk_requests')
            .doc(requestId)
            .set(
          <String, dynamic>{
            'status': 'cancelled',
            'cancelledBy': 'owner',
            'cancelledByUid': uid,
            'cancelledAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walk cancelled successfully.',
            ),
          ),
        );
    } on FirebaseException catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'Permission denied by Firestore rules.'
                  : 'Unable to cancel walk.',
            ),
          ),
        );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to cancel walk.',
            ),
          ),
        );
    }
  }

  // ==========================================================
  // REQUEST ID
  // ==========================================================

  String _readActiveWalkRequestId(
    ActiveWalk activeWalk,
  ) {
    return activeWalk.requestId.trim();
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker(
    String phone,
  ) async {
    if (phone.trim().isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone.trim(),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ==========================================================
  // SMS
  // ==========================================================

  Future<void> _smsWalker(
    String phone,
  ) async {
    if (phone.trim().isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'sms',
      path: phone.trim(),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  Future<void> _openNavigation(
    GeoPoint? location,
  ) async {
    if (location == null) {
      return;
    }

    final String lat =
        location.latitude.toString();

    final String lng =
        location.longitude.toString();

    final Uri geoUri = Uri.parse(
      'geo:$lat,$lng?q=$lat,$lng',
    );

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }

    final Uri osmUri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng',
    );

    await launchUrl(
      osmUri,
      mode: LaunchMode.externalApplication,
    );
  }

  // ==========================================================
  // STRING READER
  // ==========================================================

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return fallback;
  }

  // ==========================================================
  // GEOPOINT READER
  // ==========================================================

  static GeoPoint? _readGeoPoint(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value is GeoPoint) {
        return value;
      }

      if (value is Map) {
        final dynamic lat =
            value['latitude'] ??
                value['lat'];

        final dynamic lng =
            value['longitude'] ??
                value['lng'] ??
                value['lon'];

        if (lat is num &&
            lng is num) {
          return GeoPoint(
            lat.toDouble(),
            lng.toDouble(),
          );
        }
      }
    }

    return null;
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _loading() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking active walker...',
            style: TextStyle(
              color: slate,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _error(
    String message,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color: slate,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
