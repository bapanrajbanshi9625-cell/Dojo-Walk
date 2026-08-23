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

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // OWNER ID
  //
  // Firebase Auth UID:
  // XDYijQj3wzfJj3PAETlP9L59Z3e2
  //
  // ownerProfiles:
  // authUid -> ownerId
  //
  // Example:
  // OWN26GH0002
  // ============================================================

  Future<String?> getOwnerId() async {
    final String? uid = authUid;

    if (uid == null) {
      return null;
    }

    // ----------------------------------------------------------
    // First: authUid
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
            snapshot.docs.first.data();

        final String ownerId =
            _string(data['ownerId']);

        if (ownerId.isNotEmpty) {
          return ownerId;
        }
      }
    } catch (_) {
      // Continue to fallback.
    }

    // ----------------------------------------------------------
    // Second: document ID == auth UID
    // ----------------------------------------------------------

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore
              .collection('ownerProfiles')
              .doc(uid)
              .get();

      if (doc.exists) {
        final Map<String, dynamic>? data =
            doc.data();

        if (data != null) {
          final String ownerId =
              _string(data['ownerId']);

          if (ownerId.isNotEmpty) {
            return ownerId;
          }
        }
      }
    } catch (_) {
      // Safe fallback.
    }

    return null;
  }

  // ============================================================
  // OWNER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getOwnerProfile() async {
    final String? uid = authUid;

    if (uid == null) {
      return null;
    }

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
        return snapshot.docs.first.data();
      }
    } catch (_) {}

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore
              .collection('ownerProfiles')
              .doc(uid)
              .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}

    return null;
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

    final String name =
        _string(profile['ownerName']);

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

    return pets
        .whereType<Map>()
        .map(
          (Map pet) => Map<String, dynamic>.from(pet),
        )
        .toList();
  }

  static String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
