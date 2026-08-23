import 'package:flutter/material.dart';

class DojoShadows {
  DojoShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 7),
    ),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x5958E0D0),
      blurRadius: 28,
      spreadRadius: 1,
      offset: Offset(0, 9),
    ),
  ];

  static const List<BoxShadow> strongGlow = [
    BoxShadow(
      color: Color(0x7358E0D0),
      blurRadius: 35,
      spreadRadius: 2,
      offset: Offset(0, 10),
    ),
  ];
}
