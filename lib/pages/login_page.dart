import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/login_controller.dart';
import '../core/app_routes.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/tv_score_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackdropGroup(
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              width: 170,
                              height: 170,
                              child: SvgPicture.asset(
                                'lib/assets/tvScoreLogin.svg',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AuthTextField(
                          label: 'Email',
                          hintText: 'Digite seu e-mail...',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira seu e-mail.';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Por favor, insira um e-mail válido.';
                            }
                            return null;
                          },
                          controller: _controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Senha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AuthTextField(
                          label: 'Senha',
                          hintText: 'Digite sua senha...',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira sua senha.';
                            }
                            if (value.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres.';
                            }
                            return null;
                          },
                          controller: _controller.passwordController,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) => TextButton(
                              onPressed: _controller.isLoading
                                  ? null
                                  : () => Navigator.pushNamed(
                                      context,
                                      AppRoutes.recovery,
                                      arguments:
                                          _controller.emailController.text,
                                    ),
                              child: const Text('Esqueceu a senha?'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: SizedBox(
                            width: 165,
                            height: 50,
                            child: ListenableBuilder(
                              listenable: _controller,
                              builder: (context, child) => FilledButton(
                                onPressed: _controller.isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        final success = await _controller
                                            .submit();
                                        if (!context.mounted) return;
                                        if (!success) {
                                          TvScoreSnackbar.error(
                                            context,
                                            _controller.errorMessage ??
                                                'Não foi possível entrar. Tente novamente.',
                                          );
                                          return;
                                        }
                                        Navigator.of(
                                          context,
                                        ).pushReplacementNamed(AppRoutes.home);
                                      },
                                child: _controller.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Ainda não tem uma conta?',
                              style: TextStyle(
                                color: Color(0xFF8B9BB8),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.register,
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Cadastre-se',
                                style: TextStyle(
                                  color: Color(0xFFB6D0FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
}
