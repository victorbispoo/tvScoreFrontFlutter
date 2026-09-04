import 'package:flutter/material.dart';

import '../services/api_services.dart';
import 'movie_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: ApiService().getHighlights(),
      builder: (context, snapshot) {
        final movies = snapshot.data ?? const <Map<String, String>>[];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'lib/assets/Logo tv score.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Filmes e séries para você acompanhar.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 28),
            const Text(
              'Destaques',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => MovieCard(movie: movies[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}
