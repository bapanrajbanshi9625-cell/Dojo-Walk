// ==========================================================
// START SEARCH
// ==========================================================

Future<InstaWalkSearchResult> startSearch({
  required String ownerId,
  required String ownerName,
  required String address,
  required GeoPoint ownerLocation,
}) async {

  final User? user =
      _auth.currentUser;


  if (user == null) {
    return const InstaWalkSearchResult.failure(
      message: 'Please login first.',
      errorCode: 'unauthenticated',
    );
  }



  final String cleanOwnerId =
      ownerId.trim();

  final String cleanOwnerName =
      ownerName.trim().isEmpty
          ? 'Dog Owner'
          : ownerName.trim();


  final String cleanAddress =
      address.trim();



  if (cleanOwnerId.isEmpty) {
    return const InstaWalkSearchResult.failure(
      message: 'Owner ID missing.',
      errorCode: 'missing-owner-id',
    );
  }


  if (cleanAddress.isEmpty) {
    return const InstaWalkSearchResult.failure(
      message: 'Address missing.',
      errorCode: 'missing-address',
    );
  }



  try {


    final DocumentReference<
        Map<String, dynamic>> ref =
        await _helper.createRequest(
      data: {

        // ==================================================
        // STATUS
        // ==================================================

        'status':
            'searching',


        // ==================================================
        // TYPE
        // ==================================================

        'searchType':
            'insta_walk',

        'senderRole':
            'owner',



        // ==================================================
        // AUTH
        // ==================================================

        'senderUid':
            user.uid,

        'ownerAuthUid':
            user.uid,



        // ==================================================
        // OWNER
        // ==================================================

        'ownerId':
            cleanOwnerId,

        'businessId':
            cleanOwnerId,

        'ownerName':
            cleanOwnerName,

        'address':
            cleanAddress,



        // ==================================================
        // LOCATION
        // ==================================================

        'ownerLocation':
            ownerLocation,

        'ownerLocationType':
            'search_snapshot',



        // ==================================================
        // WALKER
        // ==================================================

        'walkerUid':
            null,

        'walkerId':
            null,

        'walkerName':
            null,


        'acceptedBy':
            null,

        'acceptedAt':
            null,



        // ==================================================
        // TIME
        // ==================================================

        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );



    _activeRequestId =
        ref.id;



    return InstaWalkSearchResult.success(
      requestId:
          ref.id,
    );


  } on FirebaseException catch (e) {


    return InstaWalkSearchResult.failure(
      message:
          e.message ??
          'Firestore error',
      errorCode:
          e.code,
    );


  } catch (e) {


    return const InstaWalkSearchResult.failure(
      message:
          'Unable to start search.',
    );

  }
}
