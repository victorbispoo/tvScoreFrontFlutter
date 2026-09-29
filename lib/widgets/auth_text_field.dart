import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final IconButton? suffixIcon;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    
    textInputAction: textInputAction,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      suffixIcon: suffixIcon,
      suffixIconColor: Colors.white60,
      labelText: label,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFF15243D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF5B9EFF), width: 1.5),
      ),
    ),
  );
}

class AuthTextField extends AppTextField {
  const AuthTextField({
    super.key,
    required super.label,
    super.controller,
    super.obscureText,
    super.textInputAction,
    super.keyboardType,
    super.onChanged,
    super.prefixIcon,
    super.suffixIcon,
    super.hintText,
  });
}
