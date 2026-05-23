import 'package:flutter/material.dart';

class SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;

  const SoftField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fillColor = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final radius = BorderRadius.circular(18);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        floatingLabelStyle: tt.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }
}
