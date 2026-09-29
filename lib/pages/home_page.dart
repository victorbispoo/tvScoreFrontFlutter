import 'package:flutter/material.dart';

import '../services/api_services.dart';
import 'movie_card.dart';

class LegacyHomePage extends StatefulWidget {
  const LegacyHomePage({super.key});

  @override
  State<LegacyHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<LegacyHomePage>
    with AutomaticKeepAliveClientMixin {
  late final Future<List<Map<String, String>>> _highlightsFuture;

  @override
  void initState() {
    super.initState();
    _highlightsFuture = ApiService().getHighlights();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _highlightsFuture,
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
                  'lib/assets/logoTvScore.png',
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.60,
              ),
              itemCount: movies.length,
              itemBuilder: (_, i) => MovieCard(movie: movies[i]),
            ),
          ],
        );
      },
    );
  }
}

class HomePage extends LegacyHomePage {
  const HomePage({super.key});
}
