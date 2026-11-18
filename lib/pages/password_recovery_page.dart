import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_routes.dart';
import '../core/light_logo_color_mapper.dart';
import '../core/password_recovery_rules.dart';
import '../services/api_services.dart';
import '../widgets/auth_text_field.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage.request({super.key, this.email = ''})
    : resetting = false,
      token = null;
  const PasswordRecoveryPage.reset({super.key, required this.token})
    : resetting = true,
      email = '';

  final bool resetting;
  final String email;
  final String? token;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final _api = ApiService();
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _timer;
  bool _busy = false;
  bool _rejectedLink = false;
  bool _messageIsError = false;
  String? _message;

  int get _seconds {
    final retryAt = widget.resetting ? _api.resetRetryAt : _api.recoveryRetryAt;
    final milliseconds =
        retryAt?.difference(DateTime.now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  bool get _invalidLink =>
      widget.resetting &&
      (_rejectedLink || !PasswordRecoveryRules.isValidToken(widget.token));

  @override
  void initState() {
    super.initState();
    _watchCooldown();
  }

  void _watchCooldown() {
    _timer?.cancel();
    if (_seconds == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {});
      if (_seconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _login({bool passwordReset = false}) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
      arguments: (passwordReset: passwordReset),
    );
  }

  Future<void> _submit() async {
    if (_busy ||
        _invalidLink ||
        _seconds > 0 ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    FocusScope.of(context).unfocus();
    try {
      if (widget.resetting) {
        await _api.resetPassword(widget.token!, _password.text);
        if (!mounted) return;
        _login(passwordReset: true);
      } else {
        final message = await _api.requestPasswordRecovery(_email.text);
        if (mounted) {
          setState(() {
            _message = message;
            _messageIsError = false;
          });
        }
      }
    } on InvalidRecoveryLink {
      if (mounted) setState(() => _rejectedLink = true);
    } on RecoveryRateLimit {
      if (mounted) {
        setState(() {
          _message = 'Muitas tentativas. Aguarde para tentar novamente.';
          _messageIsError = true;
        });
        _watchCooldown();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = error is FormatException
              ? error.message
              : 'Não foi possível concluir. Tente novamente.';
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: BackdropGroup(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          'lib/assets/tvScoreLogin.svg',
                          width: 170,
                          height: 170,
                          colorMapper: theme.brightness == Brightness.light
                              ? const LightLogoColorMapper()
                              : null,
                        ),
                      ),
                      SizedBox(height: 40,),
                      Text(
                        widget.resetting
                            ? 'Redefinir senha'
                            : 'Recuperar senha',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (_invalidLink)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _rejectedLink
                                ? 'O link é inválido, expirou ou já foi usado. Solicite um novo.'
                                : 'Link de recuperação inválido. Solicite um novo link.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        )
                      else if (widget.resetting) ...[
                        const Text(
                          'Crie uma senha com pelo menos 6 caracteres e sem emojis.',
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'Nova senha',
                          controller: _password,
                          isPassword: true,
                          enabled: !_busy,
                          textInputAction: TextInputAction.next,
                          validator: PasswordRecoveryRules.validatePassword,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirmar nova senha',
                          controller: _confirmation,
                          isPassword: true,
                          enabled: !_busy,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (value) => value != _password.text
                              ? 'As senhas não coincidem.'
                              : null,
                        ),
                      ] else ...[
                        const Text(
                          'Informe seu e-mail para solicitar instruções de recuperação.',
                        ),
                        const SizedBox(height: 20),
                        AuthTextField(
                          label: 'E-mail',
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (value) =>
                              (value?.trim().length ?? 0) <= 254 &&
                                  RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Informe um e-mail válido.',
                        ),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _messageIsError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_invalidLink)
                        FilledButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.recovery),
                          child: const Text('Solicitar novo link'),
                        )
                      else
                        FilledButton(
                          onPressed: _busy || _seconds > 0 ? null : _submit,
                          child: Text(
                            _busy
                                ? 'Aguarde...'
                                : _seconds > 0
                                ? 'Tentar em ${_seconds}s'
                                : widget.resetting
                                ? 'Redefinir senha'
                                : 'Enviar solicitação',
                          ),
                        ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                if (widget.resetting ||
                                    !Navigator.of(context).canPop()) {
                                  _login();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                        child: const Text('Voltar ao login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
