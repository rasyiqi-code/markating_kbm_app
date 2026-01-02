import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';

class SalesTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  const SalesTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.inputFormatters,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(fontSize: 16),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(context),
      onChanged: onChanged,
      validator: validator ?? (v) => v!.isEmpty ? 'Wajib diisi ya' : null,
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.outfit(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor:
          Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}
