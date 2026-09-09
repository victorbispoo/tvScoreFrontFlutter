import 'package:flutter/material.dart';

import '../main.dart';
import 'register_page.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_text_field.dart';
import 'redesigned_screens.dart';

class LegacyLoginPage extends StatefulWidget {
  const LegacyLoginPage({super.key});

  @override
  State<LegacyLoginPage> createState() => _LegacyLoginPageState();
}

class _LegacyLoginPageState extends State<LegacyLoginPage> {
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 112,
                  child: Image.asset(
                    'lib/assets/logoTvScore.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  label: 'E-mail',
                  controller: _controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _controller.onChanged(),
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  label: 'Senha',
                  controller: _controller.passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _controller.onChanged(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final loggedIn = await _controller.submit();
                    if (!mounted || !loggedIn) return;
                    navigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const AppShell()),
                    );
                  },
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Entrar')),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text('Ainda não tem uma conta? Cadastre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScreen(
    isRegister: false,
    onSubmit: () => Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
    ),
  );
}
