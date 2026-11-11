import 'package:flutter/material.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';

import '../controllers/register_controller.dart';
import '../core/app_routes.dart';
import '../services/api_services.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final RegisterController _controller;
  bool _obscurePassword = true;
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
          ? 'Conta criada, mas não foi possível entrar automaticamente'
                'Faça login para continuar'
          : error is FormatException
          ? error.message
          : 'Não foi possível criar a conta. Tente novamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

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
    appBar: AppBar(title: const Text('Criar conta')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
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
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: !_busy && _controller.canSubmit ? _register : null,
            child: const SizedBox(
              width: double.infinity,
              child: Center(child: Text('Cadastrar')),
            ),
          ),
        ],
      ),
    ),
  );
}
