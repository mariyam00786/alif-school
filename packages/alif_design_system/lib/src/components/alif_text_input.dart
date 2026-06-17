import 'package:flutter/material.dart';

class AlifTextInput extends StatelessWidget {
  const AlifTextInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hintText),
    );
  }
}
