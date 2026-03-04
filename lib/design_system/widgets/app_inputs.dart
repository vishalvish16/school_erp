// =============================================================================
// FILE: lib/shared/widgets/app_inputs.dart
// PURPOSE: Reusable text fields with validation and password visibility toggle
// =============================================================================

import 'package:flutter/material.dart';
import '../tokens/theme.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          enabled: enabled,
          style: AppTextStyles.body(color: Theme.of(context).colorScheme.onSurface),
          decoration: AppInputStyles.decoration(
            context: context,
            label: label,
            hint: hint,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            isRequired: isRequired,
          ),
        ),
      ],
    );
  }
}

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.isRequired = false,
    this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscureText,
      isRequired: widget.isRequired,
      onChanged: widget.onChanged,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}
