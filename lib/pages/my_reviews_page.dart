import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_haptics.dart';
import '../core/app_routes.dart';
import '../core/rating_scale.dart';
import '../models/review.dart';
import '../services/api_services.dart';
import '../widgets/content_poster.dart';
import '../widgets/tv_score_confirmation_dialog.dart';
import '../widgets/tv_score_segmented_control.dart';
import '../widgets/tv_score_snackbar.dart';

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
    await AppRoutes.openDetails(context, content: review.content);

    if (mounted) setState(() {});
  }

  Future<void> _deleteReview(Review review) async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      final confirmed = await showTvScoreConfirmation(
        context,
        title: 'Excluir avaliação',
        description:
            'Sua avaliação de ${review.content['title'] ?? 'este título'} será removida permanentemente.',
        emphasis: review.content['title'],
        confirmLabel: 'Excluir',
        destructive: true,
      );
      if (confirmed != true || !mounted) return;

      try {
        await _api.deleteReview(review);
        if (mounted) {
          AppHaptics.confirmation();
          setState(() {});
        }
      } catch (_) {
        if (!mounted) return;
        AppHaptics.error();
        TvScoreSnackbar.error(
          context,
          'Não foi possível excluir a avaliação. Tente novamente.',
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
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
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            HugeIconsStroke.star,
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
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildReviews(reviews, average),
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(Review review) => _MyReviewCard(
    review: review,
    deleting: _deleting,
    onEdit: () => _editReview(review),
    onDelete: () => _deleteReview(review),
  );

  Widget _buildReviews(List<Review> reviews, double average) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth - 40 >= 900 ? 2 : 1;
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 1 + (reviews.length / columns).ceil(),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${reviews.length}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Avaliações',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  average.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Sua nota média',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TvScoreSegmentedControl<bool>(
                  options: const {
                    false: 'Mais recentes',
                    true: 'Maiores notas',
                  },
                  selectedValue: _highestFirst,
                  onChanged: (value) => setState(() => _highestFirst = value),
                ),
                const SizedBox(height: 12),
              ],
            );
          }
          final first = (index - 1) * columns;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _reviewCard(reviews[first])),
                if (columns == 2) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: first + 1 < reviews.length
                        ? _reviewCard(reviews[first + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({
    required this.review,
    required this.deleting,
    required this.onEdit,
    required this.onDelete,
  });

  final Review review;
  final bool deleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter.grouped(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              height: 130,
              child: ContentPoster(content: review.content),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.content['title'] ?? 'Título indisponível',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        HugeIconsSolid.star,
                        size: 15,
                        color: RatingScale.color(review.rating),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${review.rating.toStringAsFixed(1)}/10',
                          style: TextStyle(
                            color: RatingScale.color(review.rating),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${review.date.day.toString().padLeft(2, '0')}/${review.date.month.toString().padLeft(2, '0')}/${review.date.year}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (review.comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 2,
                    children: [
                      TextButton.icon(
                        onPressed: deleting ? null : onEdit,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          minimumSize: const Size(48, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        icon: const Icon(
                          HugeIconsStroke.pencilEdit01,
                          size: 16,
                        ),
                        label: const Text('Editar'),
                      ),
                      TextButton.icon(
                        onPressed: deleting ? null : onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE59AA5),
                          minimumSize: const Size(48, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        icon: const Icon(HugeIconsStroke.delete02, size: 16),
                        label: const Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
