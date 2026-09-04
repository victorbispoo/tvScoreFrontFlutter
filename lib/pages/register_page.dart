import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar conta')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(decoration: InputDecoration(labelText: 'Nome')),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'E-mail')),
          SizedBox(height: 12),
          TextField(decoration: InputDecoration(labelText: 'Senha')),
        ],
      ),
    ),
  );
}
