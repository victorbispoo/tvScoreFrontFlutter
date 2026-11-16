import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_routes.dart';
import '../services/api_services.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/tv_score_snackbar.dart';

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
  String? _message;

  int get _seconds {
    final milliseconds =
        _api.recoveryRetryAt?.difference(DateTime.now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  bool get _invalidLink => widget.resetting && (widget.token?.isEmpty ?? true);

  @override
  void initState() {
    super.initState();
    if (!widget.resetting) _watchCooldown();
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

  void _login() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  Future<void> _submit() async {
    if (_busy ||
        _invalidLink ||
        (!widget.resetting && _seconds > 0) ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (widget.resetting) {
        await _api.resetPassword(widget.token!, _password.text);
        if (!mounted) return;
        _login();
        TvScoreSnackbar.success(
          context,
          'Senha redefinida. Entre com sua nova senha.',
        );
      } else {
        final message = await _api.requestPasswordRecovery(_email.text);
        if (mounted) setState(() => _message = message);
      }
    } on RecoveryRateLimit {
      if (mounted) {
        setState(
          () => _message =
              'Muitas solicitações. Aguarde o intervalo para tentar novamente.',
        );
        _watchCooldown();
      }
    } catch (error) {
      if (mounted) {
        TvScoreSnackbar.error(
          context,
          error is FormatException
              ? error.message
              : 'Não foi possível concluir. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BackdropGroup(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                      ),
                    ),
                    Text(
                      widget.resetting ? 'Redefinir senha' : 'Recuperar senha',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_invalidLink)
                      const Text(
                        'Link de recuperação inválido. Solicite um novo link.',
                      )
                    else if (widget.resetting) ...[
                      AuthTextField(
                        label: 'Nova senha',
                        controller: _password,
                        isPassword: true,
                        enabled: !_busy,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final bytes = utf8.encode(value ?? '').length;
                          return bytes < 8 || bytes > 72
                              ? 'Use entre 8 e 72 bytes UTF-8.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'Confirmar nova senha',
                        controller: _confirmation,
                        isPassword: true,
                        enabled: !_busy,
                        textInputAction: TextInputAction.done,
                        validator: (value) => value != _password.text
                            ? 'As senhas não coincidem.'
                            : null,
                      ),
                    ] else ...[
                      const Text(
                        'Informe seu e-mail para solicitar instruções de recuperação.',
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        label: 'E-mail',
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Informe um e-mail válido.',
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Semantics(liveRegion: true, child: Text(_message!)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed:
                          _busy ||
                              _invalidLink ||
                              (!widget.resetting && _seconds > 0)
                          ? null
                          : _submit,
                      child: Text(
                        _busy
                            ? 'Aguarde...'
                            : !widget.resetting && _seconds > 0
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
