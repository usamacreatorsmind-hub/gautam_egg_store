import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KycTextField extends StatelessWidget {
  final String label;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  const KycTextField({
    super.key,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.controller,
    this.validator,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints?.toList(),
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
