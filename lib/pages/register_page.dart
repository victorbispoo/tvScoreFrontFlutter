import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_routes.dart';
import '../core/password_recovery_rules.dart';
import '../services/api_services.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/profile_photo_editor.dart';
import '../widgets/tv_score_snackbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.returnToOrigin = false});

  final bool returnToOrigin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _photoUrl = ValueNotifier<String?>(null);
  Uint8List? _photoBytes;
  bool _photoBusy = false;

  static bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(value);
  }

  bool _busy = false;

  String _errorMessageFor(Object? error, {required bool accountCreated}) {
    if (accountCreated) {
      return 'Conta criada, mas não foi possível entrar automaticamente. Faça login para continuar.';
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'Não foi possível criar a conta. Tente novamente.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy || _photoBusy) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final api = ApiService();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final photo = _photoBytes;

    var accountCreated = false;

    setState(() {
      _busy = true;
    });

    try {
      await api.register(name, email, password);
      accountCreated = true;

      if (!mounted) return;

      await api.loginApi(email, password, isActive: () => mounted);

      if (photo != null && mounted) await _uploadPhoto(api, photo);
      if (!mounted) return;
      setState(() => _busy = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: Theme.of(context).brightness == Brightness.dark,
        builder: (_) => const ContentPreferencesDialog(),
      );

      if (!mounted) return;

      if (widget.returnToOrigin) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    } catch (error) {
      if (!mounted) return;

      final message = _errorMessageFor(error, accountCreated: accountCreated);
      TvScoreSnackbar.error(context, message);

      if (accountCreated) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _uploadPhoto(ApiService api, Uint8List photo) async {
    while (mounted) {
      try {
        await api.uploadProfilePhoto(photo);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _busy = false);
        final retry = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Conta criada'),
              content: const Text(
                'Não foi possível enviar sua foto. Você pode tentar novamente ou adicioná-la depois pelo Perfil.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continuar sem foto'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        );
        if (retry != true || !mounted) return;
        setState(() => _busy = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(HugeIconsStroke.arrowLeft01),
      ),
      title: const Text('Criar conta'),
    ),
    body: BackdropGroup(
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 36).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: AuthFormLayout(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProfilePhotoEditor(
                          name: _nameController.text,
                          photoUrl: _photoUrl,
                          photoBytes: _photoBytes,
                          enabled: !_busy,
                          onBusy: (busy) => setState(() => _photoBusy = busy),
                          onPendingChanged: (_) {},
                          onUpload: (bytes, _) async {
                            setState(() => _photoBytes = bytes);
                          },
                          onRemove: () async {
                            setState(() => _photoBytes = null);
                          },
                        ),
                        const SizedBox(height: 24),
                        AuthTextField(
                          label: 'Nome',
                          initialField: true,
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira seu nome.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          label: 'E-mail',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira seu e-mail.';
                            }
                            if (!_isValidEmail(value.trim())) {
                              return 'Por favor, insira um e-mail válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          label: 'Senha',
                          controller: _passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _register(),
                          onChanged: (_) => setState(() {}),
                          validator: PasswordRecoveryRules.validatePassword,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _busy || _photoBusy ? null : _register,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Cadastrar'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'J\u00e1 tem uma conta?',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.maybePop(context),
                              child: const Text('Entrar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
