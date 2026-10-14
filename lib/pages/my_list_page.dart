import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../widgets/movie_card.dart';

class MyListPage extends StatefulWidget {
  const MyListPage({super.key});

  @override
  State<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends State<MyListPage> {
  final _api = ApiService();

  Future<void> _removeMovie(Map<String, String> movie) async {
    try {
      await _api.toggleSaved(movie);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível remover o título.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = ApiService.savedMovies;
    return Scaffold(
      appBar: AppBar(title: const Text('Minha lista')),
      body: SafeArea(
        child: movies.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 56,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sua lista está vazia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Abra um título na Home ou na busca e adicione à sua lista.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 340,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    Expanded(
                      child: MovieCard(
                        movie: movies[index],
                        onChanged: () => setState(() {}),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _removeMovie(movies[index]),
                      icon: const Icon(
                        Icons.bookmark_remove_outlined,
                        size: 18,
                      ),
                      label: const Text('Remover'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
