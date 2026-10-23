import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_services.dart';
import '../widgets/movie_card.dart';
import 'favorites_page.dart';
import 'my_reviews_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, String>>> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = ApiService().getHighlights();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    final future = ApiService().getHighlights();
    setState(() => _catalog = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: _refresh,
              child: const Text('Tentar novamente'),
            ),
          );
        }
        final movies = snapshot.data ?? [];
        final best = movies.toList()
          ..sort(
            (a, b) =>
                double.parse(b['score']!).compareTo(double.parse(a['score']!)),
          );
        final recent = movies.toList()
          ..sort((a, b) => b['year']!.compareTo(a['year']!));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'lib/assets/logoTvScore.svg',
                      width: 130,
                      height: 70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sua próxima boa história começa aqui.',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Descubra filmes e séries, salve seus favoritos e compartilhe sua opinião.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.bookmark_border, size: 18),
                          label: const Text('Favoritos'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FavoritesPage(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Minhas avaliações'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyReviewsPage(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildCarousel(
                title: 'Destaques',
                subtitle: 'Histórias que merecem sua atenção',
                movies: movies.take(6).toList(),
              ),
              _buildCarousel(
                title: 'Mais bem avaliados',
                subtitle: 'As maiores notas do catálogo',
                movies: best.take(8).toList(),
              ),
              _buildCarousel(
                title: 'Mais recentes no catálogo',
                movies: recent.take(8).toList(),
              ),
              _buildCarousel(
                title: 'Ação e aventura',
                movies: movies
                    .where((movie) => movie['genre']!.contains('Ação'))
                    .toList(),
              ),
              _buildCarousel(
                title: 'Ficção científica',
                movies: movies
                    .where((movie) => movie['genre']!.contains('Ficção'))
                    .toList(),
              ),
              _buildCarousel(
                title: 'Drama e grandes clássicos',
                movies: movies
                    .where((movie) => movie['genre']!.contains('Drama'))
                    .toList(),
              ),
              _buildCarousel(
                title: 'Séries para maratonar',
                movies: movies
                    .where((movie) => movie['type'] == 'series')
                    .toList(),
              ),
              _buildCarousel(
                title: 'Na sua lista',
                movies: ApiService.savedMovies,
              ),
            ],
          ),
        );
      },
    );
  }

  // O mesmo layout é usado em cada carrossel da Home.
  Widget _buildCarousel({
    required String title,
    String? subtitle,
    required List<Map<String, String>> movies,
  }) {
    if (movies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (_, index) => SizedBox(
                width: 160,
                child: MovieCard(
                  movie: movies[index],
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
