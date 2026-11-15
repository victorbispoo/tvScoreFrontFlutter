import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_theme.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.hintText,
    this.validator,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final IconButton? suffixIcon;
  final FormFieldValidator<String>? validator;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _focusNode = FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_updateFocus);
  }

  void _updateFocus() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_updateFocus);
    _focusNode.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    const error = Color(0xFFE5A0AC);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: widget.isPassword && _hidden,
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          style: TextStyle(
            color: widget.enabled ? Colors.white : Colors.white60,
          ),
          cursorColor: AppTheme.primary,
          decoration: InputDecoration(
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: widget.enabled
                        ? () => setState(() => _hidden = !_hidden)
                        : null,
                    icon: Icon(
                      _hidden ? HugeIconsStroke.viewOff : HugeIconsStroke.view,
                      size: 20,
                    ),
                  )
                : widget.suffixIcon,
            suffixIconColor: widget.enabled ? Colors.white70 : Colors.white38,
            labelText: widget.label,
            hintText: widget.hintText,
            labelStyle: const TextStyle(color: Colors.white60),
            hintStyle: const TextStyle(color: Colors.white60),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            prefixIcon: widget.prefixIcon,
            prefixIconColor: widget.enabled ? Colors.white70 : Colors.white38,
            filled: true,
            fillColor: const Color(0xFF14253D).withValues(
              alpha: widget.enabled ? (_focusNode.hasFocus ? .96 : .92) : .7,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: _border(AppTheme.primary.withValues(alpha: .18)),
            enabledBorder: _border(AppTheme.primary.withValues(alpha: .18)),
            focusedBorder: _border(
              AppTheme.primary.withValues(alpha: .8),
              width: 1.5,
            ),
            disabledBorder: _border(Colors.white.withValues(alpha: .06)),
            errorBorder: _border(error.withValues(alpha: .65)),
            focusedErrorBorder: _border(error, width: 1.5),
            errorStyle: const TextStyle(
              color: error,
              fontSize: 12,
              height: 1.4,
            ),
            errorMaxLines: 3,
          ),
        ),
      ),
    );
  }
}
