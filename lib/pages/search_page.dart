import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Pesquisar',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Encontre filmes, séries e pessoas.',
        style: TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 24),
      TextField(
        decoration: InputDecoration(
          hintText: 'Busque por um título...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 40),
      const Icon(Icons.movie_outlined, size: 54, color: Colors.white54),
      const SizedBox(height: 16),
      const Text(
        'O que você quer assistir?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'Digite um título para começar a pesquisar.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    ],
  );
}
