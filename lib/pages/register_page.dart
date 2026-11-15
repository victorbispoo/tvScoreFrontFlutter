import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../controllers/register_controller.dart';
import '../core/app_routes.dart';
import '../core/app_theme.dart';
import '../services/api_services.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/tv_score_snackbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegisterController _controller;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy || !_controller.canSubmit) return;

    final api = ApiService();
    final name = _controller.nameController.text.trim();
    final email = _controller.emailController.text.trim();
    final password = _controller.passwordController.text;

    var accontCreated = false;

    setState(() {
      _busy = true;
    });

    try {
      await api.register(name, email, password);
      accontCreated = true;

      if (!mounted) return;

      await api.loginApi(email, password);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const GenrePreferencesDialog(),
      );

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } catch (error) {
      if (!mounted) return;

      final message = accontCreated
          ? 'Conta criada, mas não foi possível entrar automaticamente. Faça login para continuar.'
          : error is FormatException
          ? error.message
          : 'Não foi possível criar a conta. Tente novamente.';
      TvScoreSnackbar.error(context, message);

      if (accontCreated) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: AppTheme.scaffoldBackground,
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
                minHeight: constraints.maxHeight - 36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _RegistrationAvatar(),
                      const SizedBox(height: 24),
                      AuthTextField(
                        label: 'Nome',
                        controller: _controller.nameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label: 'E-mail',
                        controller: _controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        label: 'Senha',
                        controller: _controller.passwordController,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: !_busy && _controller.canSubmit
                              ? _register
                              : null,
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
                          const Text(
                            'J\u00e1 tem uma conta?',
                            style: TextStyle(color: Color(0xFF8B9BB8)),
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
  );
}

class _RegistrationAvatar extends StatelessWidget {
  const _RegistrationAvatar();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Foto de perfil indispon\u00edvel no cadastro',
    child: SizedBox.square(
      dimension: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceHighlight.withValues(alpha: .55),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: .22),
              ),
            ),
            child: const Center(
              child: Icon(
                HugeIconsStroke.user,
                size: 38,
                color: Color(0xFFB6D0FF),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(
                  color: AppTheme.scaffoldBackground,
                  width: 2,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  HugeIconsStroke.camera01,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
