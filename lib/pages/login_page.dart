import 'package:flutter/material.dart';

import '../main.dart';
import 'register_page.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller;
  bool _obscurePassword = true;

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
      body: SafeArea(child: _AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AuthLogo(),
                  const SizedBox(height: 12),
                  const _AuthLabel('Email'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    label: 'Email',
                    hintText: 'Digite seu e-mail...',
                    controller: _controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _controller.onChanged(),
                  ),
                  const SizedBox(height: 18),
                  const _AuthLabel('Senha'),
                  const SizedBox(height: 8),
                  AuthTextField(
                    label: 'Senha',
                    hintText: 'Digite sua senha...',
                    controller: _controller.passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => _controller.onChanged(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 38),
                  Center(
                    child: SizedBox(
                      width: 165,
                      height: 50,
                      child: FilledButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final loggedIn = await _controller.submit();
                          if (!mounted || !loggedIn) return;
                          navigator.pushReplacement(
                            MaterialPageRoute(builder: (_) => const AppShell()),
                          );
                        },
                        child: const Text('Entrar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _AuthFooter(
                    prompt: 'Ainda não tem uma conta?',
                    action: 'Cadastre-se',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E3451),
          Color(0xFF1B2F4A),
          Color(0xFF102035),
          Color(0xFF0A1628),
        ],
      ),
    ),
    child: Center(child: child),
  );
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 300,
        height: 300,
        child: Image.asset('lib/assets/tvScoreLogin.png', fit: BoxFit.cover),
      ),
    ],
  );
}

class _AuthLabel extends StatelessWidget {
  const _AuthLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.w500,
      height: 1.33,
    ),
  );
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        prompt,
        style: const TextStyle(color: Color(0xFF8B9BB8), fontSize: 14),
      ),
      TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          action,
          style: const TextStyle(
            color: Color(0xFFB6D0FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
