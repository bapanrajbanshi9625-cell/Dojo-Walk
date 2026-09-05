import 'package:flutter/material.dart';

class PetData {
  // ============================================================
  // PET NAME
  // ============================================================

  final TextEditingController nameController;

  // ============================================================
  // PET DETAILS
  // ============================================================

  String? age;
  String? breed;
  String? behaviour;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  PetData({
    String? name,
    this.age,
    this.breed,
    this.behaviour,
  }) : nameController = TextEditingController(
          text: name ?? '',
        );

  // ============================================================
  // NAME
  // ============================================================

  String get name {
    return nameController.text.trim();
  }

  set name(String value) {
    nameController.text = value;
  }

  // ============================================================
  // COPY
  // ============================================================

  PetData copyWith({
    String? name,
    String? age,
    String? breed,
    String? behaviour,
  }) {
    return PetData(
      name: name ?? this.name,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      behaviour: behaviour ?? this.behaviour,
    );
  }

  // ============================================================
  // FIRESTORE MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'age': age,
      'breed': breed,
      'behaviour': behaviour,
    };
  }

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory PetData.fromMap(
    Map<String, dynamic> map,
  ) {
    return PetData(
      name: map['name']?.toString() ?? '',
      age: map['age']?.toString(),
      breed: map['breed']?.toString(),
      behaviour: map['behaviour']?.toString(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    nameController.dispose();
  }
}
