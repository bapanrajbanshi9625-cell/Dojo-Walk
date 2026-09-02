import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeOwnerService {
  HomeOwnerService._();

  static final HomeOwnerService instance =
      HomeOwnerService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CURRENT AUTH UID
  // ============================================================

  String? get authUid {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid = user.uid.trim();

    return uid.isEmpty ? null : uid;
  }

  // ============================================================
  // OWNER ID
  //
  // Firebase Auth UID
  //       ↓
  // ownerProfiles
  //       ↓
  // ownerId
  //
  // Supports:
  // 1. ownerProfiles where authUid == Firebase Auth UID
  // 2. ownerProfiles document ID == Firebase Auth UID
  // ============================================================

  Future<String?> getOwnerId() async {
    final Map<String, dynamic>? profile =
        await getOwnerProfile();

    if (profile == null) {
      return null;
    }

    final String ownerId =
        _string(profile['ownerId']);

    if (ownerId.isNotEmpty) {
      return ownerId;
    }

    // Safe fallback when ownerId is not stored.
    final String? uid = authUid;

    return uid;
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getOwnerProfile() async {
    final String? uid = authUid;

    if (uid == null) {
      return null;
    }

    // ----------------------------------------------------------
    // FIRST: QUERY BY authUid
    // ----------------------------------------------------------

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('ownerProfiles')
              .where(
                'authUid',
                isEqualTo: uid,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(
          snapshot.docs.first.data(),
        );

        data['documentId'] = snapshot.docs.first.id;

        return data;
      }
    } catch (_) {
      // Continue with document-ID fallback.
    }

    // ----------------------------------------------------------
    // SECOND: DOCUMENT ID == AUTH UID
    // ----------------------------------------------------------

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore
              .collection('ownerProfiles')
              .doc(uid)
              .get();

      if (!doc.exists) {
        return null;
      }

      final Map<String, dynamic>? data =
          doc.data();

      if (data == null) {
        return null;
      }

      final Map<String, dynamic> result =
          Map<String, dynamic>.from(data);

      result['documentId'] = doc.id;

      return result;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // OWNER NAME
  // ============================================================

  Future<String> getOwnerName() async {
    final Map<String, dynamic>? profile =
        await getOwnerProfile();

    if (profile == null) {
      return 'Owner';
    }

    final String name = _string(
      profile['ownerName'] ??
          profile['name'],
    );

    return name.isEmpty ? 'Owner' : name;
  }

  // ============================================================
  // PETS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPets() async {
    final Map<String, dynamic>? profile =
        await getOwnerProfile();

    if (profile == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic pets = profile['pets'];

    if (pets is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    for (final dynamic pet in pets) {
      if (pet is Map) {
        result.add(
          Map<String, dynamic>.from(pet),
        );
      }
    }

    return result;
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
