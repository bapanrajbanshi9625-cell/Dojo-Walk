part of 'insta_walk_container.dart';

// ============================================================
// FIND WALKER
// ============================================================

extension _FindWalkerRole on _InstaWalkContainerState {
  Future<void> _findWalker() async {
    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please login first.');
      return;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {

      // ========================================================
      // FIND OWNER PROFILE
      // =======================================================


      final DocumentSnapshot<Map<String, dynamic>>? ownerDoc =
    await _service.findOwnerProfile();


if (!mounted) {
  return;
}


if (ownerDoc == null) {

  _updateState(() {
    _checkingAddress = false;
  });


  _message(
    'Owner profile not found. Please complete your profile.',
  );

  return;
}


final Map<String, dynamic> data =
    ownerDoc.data() ?? <String, dynamic>{};


      // ========================================================
      // PET NAME
      // ========================================================

      _petName =
          _readFirstString(
        data,
        const [
          'petName',
          'Pet Name',
          'dogName',
          'Dog Name',
        ],
      );


      if(_petName.isEmpty){

        _petName =
            'Your Pet';

      }



      // ========================================================
      // ADDRESS
      // ========================================================

      final String address =
          _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );


      if(address.isEmpty){

        _updateState(() {
          _checkingAddress = false;
        });


        _message(
          'Owner address is missing. Please complete your address first.',
        );


        return;

      }




      // ========================================================
      // OWNER NAME
      // ========================================================

      String ownerName =
          _readFirstString(
        data,
        const [
          'fullName',
          'Full Name',
          'ownerName',
          'name',
        ],
      );


      if(ownerName.isEmpty){

        ownerName =
            'Dog Owner';

      }



      // ========================================================
      // LOCATION
      // ========================================================

      final Position? position =
          await _getLocation();



      if(!mounted){

        return;

      }


      if(position == null){

        _updateState(() {
          _checkingAddress = false;
        });


        return;

      }



      _ownerPosition =
          position;



      // ========================================================
      // START SEARCH
      // ========================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
      );


    } on FirebaseException catch(e){


      debugPrint(
        'Insta Walk Firebase error: '
        '${e.code} - ${e.message}',
      );


      if(!mounted){

        return;

      }


      _updateState(() {
        _checkingAddress = false;
      });


      _message(
        e.code == 'permission-denied'
            ? 'Firestore permission denied. Please check Firebase rules.'
            : 'Unable to start Insta Walk.',
      );


    } catch(e){


      debugPrint(
        'Insta Walk start error: $e',
      );


      if(!mounted){

        return;

      }


      _updateState(() {
        _checkingAddress = false;
      });


      _message(
        'Unable to start Insta Walk.',
      );

    }

  }



  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {

    try {


      final bool enabled =
          await Geolocator.isLocationServiceEnabled();



      if(!enabled){

        _message(
          'Please turn on location service.',
        );

        return null;

      }



      LocationPermission permission =
          await Geolocator.checkPermission();



      if(permission ==
          LocationPermission.denied){

        permission =
            await Geolocator.requestPermission();

      }



      if(permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever){

        _message(
          'Location permission is required.',
        );


        return null;

      }



      return await Geolocator.getCurrentPosition();



    } catch(e){


      debugPrint(
        'Location error: $e',
      );


      _message(
        'Unable to get your current location.',
      );


      return null;

    }

  }

}
