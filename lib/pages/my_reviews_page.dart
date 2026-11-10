import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/api_services.dart';
import '../widgets/content_poster.dart';
import 'details_page.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final _api = ApiService();
  bool _deleting = false;
  bool _highestFirst = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.loadMyReviews();
    } catch (error, stackTrace) {
      debugPrint('Falha ao carregar avaliações: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar suas avaliações';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _editReview(Review review) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailsPage(content: review.content)),
    );

    if (mounted) setState(() {});
  }

  Future<void> _deleteReview(Review review) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir avaliação?'),
          content: Text(
            'Excluir sua nota e comentário de "${review.content['title']}"?',
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
          const SnackBar(
            content: Text('Não foi possível excluir a avaliação.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Text(_error!, textAlign: .center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadMyReviews,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              )
            : reviews.isEmpty
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
                                  child: ContentPoster(content: review.content),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.content['title']!,
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
                                  onPressed: _deleting
                                      ? null
                                      : () => _editReview(review),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Editar'),
                                ),
                                TextButton.icon(
                                  onPressed: _deleting
                                      ? null
                                      : () => _deleteReview(review),
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
