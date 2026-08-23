import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// HOME OWNER SERVICE
/// ============================================================
///
/// Firebase Auth UID -> ownerProfiles -> Owner Business ID
///
/// Example:
/// authUid  = XDYijQj3wzfJj3PAETlP9L59Z3e2
/// ownerId  = OWN26GH0002
///
/// ============================================================

class HomeOwnerService {
  HomeOwnerService._();

  static final HomeOwnerService instance =
      HomeOwnerService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  String? get authUid {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid = user.uid.trim();

    return uid.isEmpty ? null : uid;
  }

  /// ----------------------------------------------------------
  /// Get current Owner Business ID
  /// ----------------------------------------------------------

  Future<String?> getOwnerId() async {
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

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final Map<String, dynamic> data =
          snapshot.docs.first.data();

      final dynamic value = data['ownerId'];

      if (value == null) {
        return null;
      }

      final String ownerId =
          value.toString().trim();

      return ownerId.isEmpty ? null : ownerId;
    } catch (_) {
      return null;
    }
  }

  /// ----------------------------------------------------------
  /// Get Owner profile
  /// ----------------------------------------------------------

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

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.data();
    } catch (_) {
      return null;
    }
  }
}
