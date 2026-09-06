import 'package:flutter/material.dart';

class DojoWalkShadows {
  DojoWalkShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      blurRadius: 18,
      spreadRadius: 0,
      offset: Offset(0, 6),
      color: Color(0x14000000),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
      color: Color(0x1A000000),
    ),
  ];
}
