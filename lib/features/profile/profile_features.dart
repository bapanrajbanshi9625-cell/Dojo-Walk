// File:
// lib/features/profile/profile_features.dart

import 'package:flutter/material.dart';

import 'change_mobile/change_mobile_flow.dart';

// ============================================================
// PROFILE FEATURES
// ============================================================
//
// This file contains Profile-related feature helpers.
//
// Current editable features:
// 1. Mobile Number
// 2. Address
// 3. Pet Details
//
// NOT editable from Profile:
// - Date of Birth
// - Owner Name
// - Gender
//
// Address:
// - Flat / House No. -> Mandatory
// - Street / Road -> Mandatory
// - Landmark -> Optional
// - Current Location -> Mandatory connection
//
// Pets:
// - Maximum 3 pets
// - Edit / Delete supported
// - Add Pet supported
// ============================================================


// ============================================================
// CHANGE MOBILE
// ============================================================

class ProfileMobileFeature {
  const ProfileMobileFeature._();

  static Future<void> open({
    required BuildContext context,
    required String currentNumber,
    required ValueChanged<String> onChanged,
  }) async {
    final String number = currentNumber.trim();

    if (number.isEmpty || number == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current mobile number was not found.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return ChangeMobileFlow(
          currentNumber: number,
          onChanged: onChanged,
        );
      },
    );
  }
}


// ============================================================
// PROFILE EDIT RULES
// ============================================================

class ProfileEditRules {
  const ProfileEditRules._();

  // ----------------------------------------------------------
  // Date of Birth
  // ----------------------------------------------------------

  static const bool canEditDateOfBirth = false;

  // ----------------------------------------------------------
  // Owner Name
  // ----------------------------------------------------------

  static const bool canEditOwnerName = false;

  // ----------------------------------------------------------
  // Gender
  // ----------------------------------------------------------

  static const bool canEditGender = false;

  // ----------------------------------------------------------
  // Mobile
  // ----------------------------------------------------------

  static const bool canEditMobile = true;

  // ----------------------------------------------------------
  // Address
  // ----------------------------------------------------------

  static const bool canEditAddress = true;

  // ----------------------------------------------------------
  // Pets
  // ----------------------------------------------------------

  static const bool canEditPets = true;

  static const int maximumPets = 3;

  // ----------------------------------------------------------
  // Address validation
  // ----------------------------------------------------------

  static bool isValidAddress({
    required String flatHouseNo,
    required String streetRoad,
  }) {
    return flatHouseNo.trim().isNotEmpty &&
        streetRoad.trim().isNotEmpty;
  }

  // ----------------------------------------------------------
  // Pet count validation
  // ----------------------------------------------------------

  static bool canAddPet(int currentPetCount) {
    return currentPetCount < maximumPets;
  }

  static bool isValidPetCount(int count) {
    return count >= 1 &&
        count <= maximumPets;
  }
}


// ============================================================
// PROFILE FEATURE MESSAGE
// ============================================================

class ProfileFeatureMessage {
  const ProfileFeatureMessage._();

  static void show(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static void addressRequired(
    BuildContext context,
  ) {
    show(
      context,
      'Flat / House No. and Street / Road are mandatory.',
    );
  }

  static void maximumPets(
    BuildContext context,
  ) {
    show(
      context,
      'Maximum 3 pets can be added.',
    );
  }

  static void minimumPet(
    BuildContext context,
  ) {
    show(
      context,
      'At least one pet is required.',
    );
  }

  static void locationRequired(
    BuildContext context,
  ) {
    show(
      context,
      'Location is mandatory. Please connect your current location.',
    );
  }

  static void dobNotEditable(
    BuildContext context,
  ) {
    show(
      context,
      'Date of Birth cannot be changed.',
    );
  }
}


// ============================================================
// PROFILE FEATURE LABELS
// ============================================================

class ProfileFeatureLabels {
  const ProfileFeatureLabels._();

  static const String address = 'Address';

  static const String editAddress = 'Edit';

  static const String flatHouseNo =
      'Flat / House No.';

  static const String streetRoad =
      'Street / Road';

  static const String landmark =
      'Landmark';

  static const String connectCurrentLocation =
      'Connect Current Location';

  static const String petDetails =
      'Pet Details';

  static const String addPet =
      'Add Pet';

  static const String editPet =
      'Edit Pet';

  static const String deletePet =
      'Delete Pet';

  static const String mobileNumber =
      'Mobile Number';

  static const String dateOfBirth =
      'Date of Birth';
}
