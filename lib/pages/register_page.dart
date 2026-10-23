import 'package:flutter/material.dart';

import '../controllers/register_controller.dart';
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
            onChanged: (_) => setState(_controller.onChanged),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'E-mail',
            controller: _controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(_controller.onChanged),
          ),
          const SizedBox(height: 12),
          AuthTextField(
            label: 'Senha',
            controller: _controller.passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(_controller.onChanged),
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
            onPressed: !_busy && _controller.canSubmit
                ? () async {
                    setState(() => _busy = true);
                    try {
                      await ApiService().register(
                        _controller.nameController.text,
                        _controller.emailController.text,
                        _controller.passwordController.text,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Conta de demonstração criada para esta sessão. Faça login para continuar.',
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } on FormatException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error.message)));
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  }
                : null,
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
