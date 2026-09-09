import 'package:flutter/material.dart';

import '../controllers/register_controller.dart';
import '../widgets/auth_text_field.dart';
import 'redesigned_screens.dart';

class LegacyRegisterPage extends StatefulWidget {
  const LegacyRegisterPage({super.key});

  @override
  State<LegacyRegisterPage> createState() => _LegacyRegisterPageState();
}

class _LegacyRegisterPageState extends State<LegacyRegisterPage> {
  late final RegisterController _controller;

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
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AuthTextField(
            label: 'Nome',
            controller: _controller.nameController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _controller.onChanged(),
          ),
          const SizedBox(height: 12),
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
        ],
      ),
    ),
  );
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) =>
      AuthScreen(isRegister: true, onSubmit: () => Navigator.pop(context));
}
