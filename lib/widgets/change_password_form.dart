import 'package:flutter/material.dart';

import '../core/password_recovery_rules.dart';
import 'auth_text_field.dart';

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({
    super.key,
    required this.onSubmit,
    required this.onBusy,
    required this.onSuccess,
  });

  final Future<void> Function(String, String) onSubmit;
  final ValueChanged<bool> onBusy;
  final VoidCallback onSuccess;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusy(true);
    try {
      await widget.onSubmit(_current.text, _next.text);
      if (mounted) widget.onSuccess();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Não foi possível alterar a senha. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Após alterar a senha, entre novamente na sua conta.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Senha atual',
          controller: _current,
          isPassword: true,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              value == null || value.isEmpty ? 'Informe a senha atual.' : null,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Nova senha',
          controller: _next,
          isPassword: true,
          enabled: !_busy,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final error = PasswordRecoveryRules.validatePassword(value);
            if (error != null) return error;
            if (value == _current.text) {
              return 'Escolha uma senha diferente da atual.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmar nova senha',
          controller: _confirmation,
          isPassword: true,
          enabled: !_busy,
          textInputAction: TextInputAction.done,
          validator: (value) =>
              value != _next.text ? 'As senhas não coincidem.' : null,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_busy ? 'Salvando...' : 'Alterar senha'),
        ),
      ],
    ),
  );
}
