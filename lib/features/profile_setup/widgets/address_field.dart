import 'package:flutter/material.dart';

class AddressField extends StatelessWidget {
  final TextEditingController controller;

  const AddressField({
    super.key,
    required this.controller,
  });

  static const Color orange = Color(0xFFF4511E);
  static const Color textColor = Color(0xFF222222);
  static const Color hintColor = Color(0xFF8A8A8A);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      minLines: 4,
      keyboardType: TextInputType.streetAddress,
      textCapitalization: TextCapitalization.sentences,

      // IMPORTANT:
      // Explicit text color prevents Dojo theme from
      // making entered address invisible.
      style: const TextStyle(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),

      cursorColor: orange,

      decoration: InputDecoration(
        alignLabelWithHint: true,

        prefixIcon: const Padding(
          padding: EdgeInsets.only(
            bottom: 65,
          ),
          child: Icon(
            Icons.location_on_outlined,
            color: orange,
            size: 24,
          ),
        ),

        hintText: 'Enter your address (optional)',

        hintStyle: const TextStyle(
          color: hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),

        filled: true,
        fillColor: backgroundColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: orange,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
