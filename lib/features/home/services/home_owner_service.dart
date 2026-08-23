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

  String? get authUid {
    final User? user = _auth.currentUser;
    final String uid = user?.uid.trim() ?? '';

    return uid.isEmpty ? null : uid;
  }

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

      final data = snapshot.docs.first.data();

      final String ownerId =
          data['ownerId']?.toString().trim() ?? '';

      return ownerId.isEmpty ? null : ownerId;
    } catch (_) {
      return null;
    }
  }
}
