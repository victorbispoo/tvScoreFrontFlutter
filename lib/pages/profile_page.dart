import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /*
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'José Silva',
      textAlign: TextAlign.center,
    ),
  );
  */

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Perfil',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 28),
      Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.person, size: 46),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'José Silva',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        'Organize os filmes e séries que você acompanha.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 32),
      const Card(
        child: ListTile(
          leading: Icon(Icons.bookmark_outline),
          title: Text('Minha lista'),
          subtitle: Text('Nenhum título salvo ainda'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
      const Card(
        child: ListTile(
          leading: Icon(Icons.star_outline),
          title: Text('Minhas avaliações'),
          subtitle: Text('Suas notas aparecerão aqui'),
          trailing: Icon(Icons.chevron_right),
        ),
      ),
    ],
  );
}
