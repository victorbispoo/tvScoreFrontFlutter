import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/api_services.dart';
import '../widgets/movie_card.dart';
import 'details_page.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final _api = ApiService();
  bool _highestFirst = false;

  Future<void> _editReview(Review review) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsPage(movie: review.movie)),
    );
    // Atualiza a lista depois de voltar da tela de detalhes.
    if (mounted) setState(() {});
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir avaliação?'),
        content: Text(
          'Excluir sua nota e comentário de "${review.movie['title']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteReview(review);
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a avaliação.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = List<Review>.from(ApiService.reviews);
    if (_highestFirst) {
      reviews.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      reviews.sort((a, b) => b.date.compareTo(a.date));
    }

    double average = 0;
    for (final review in reviews) {
      average += review.rating;
    }
    if (reviews.isNotEmpty) average /= reviews.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas avaliações')),
      body: SafeArea(
        child: reviews.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 64,
                        color: Colors.amber,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sua opinião merece uma nota',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Abra um filme ou série, escolha sua nota e conte o que achou. Suas avaliações aparecerão aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${reviews.length}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Avaliações'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                average.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Sua nota média'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Mais recentes'),
                        selected: !_highestFirst,
                        onSelected: (_) =>
                            setState(() => _highestFirst = false),
                      ),
                      ChoiceChip(
                        label: const Text('Maiores notas'),
                        selected: _highestFirst,
                        onSelected: (_) => setState(() => _highestFirst = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final review in reviews)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 105,
                                  child: MoviePoster(movie: review.movie),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.movie['title']!,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '★ ${review.rating}/10',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${review.date.day}/${review.date.month}/${review.date.year}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (review.comment.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(review.comment),
                            ],
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editReview(review),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteReview(review),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
