import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/widgets/episode_ratings_grid.dart';
import '../services/api_services.dart';
import '../widgets/community_review_card.dart';
import '../widgets/content_header.dart';
import '../widgets/review_form.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.content});

  final Map<String, String> content;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _api = ApiService();
  late final TextEditingController _comment;
  late double _rating;
  bool _busy = false;
  Map<String, dynamic>? _reviewSummary;
  bool _loadingCommunity = true;
  String? _communityError;
  bool _loadingMyReview = true;
  String? _myReviewError;
  List<Map<String, dynamic>> _communityReviews = [];

  @override
  void initState() {
    super.initState();
    _rating = 8.0;
    _comment = TextEditingController();
    _loadMyReview();
    _checkCommunityReviews();
  }

  Future<void> _checkCommunityReviews() async {
    setState(() {
      _loadingCommunity = true;
      _communityError = null;
    });

    try {
      final id = int.parse(widget.content['id']!);
      final type = widget.content['type']!;
      final (summary, reviews) = await (
        _api.getContentReviewSummary(id, type),
        _api.getContentReviews(id, type),
      ).wait;

      if (!mounted) return;
      setState(() {
        _reviewSummary = summary;
        _communityReviews = reviews;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _communityError = 'Não foi possível carregar as avaliações.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingCommunity = false;
        });
      }
    }
  }

  Future<void> _loadMyReview() async {
    setState(() {
      _loadingMyReview = true;
      _myReviewError = null;
    });

    try {
      await _api.loadMyReviewFor(widget.content);
      if (!mounted) return;

      final review = _api.reviewFor(widget.content);
      final rating = review?.rating ?? 8.0;

      if (!rating.isFinite || rating < 0 || rating > 10) {
        throw const FormatException(
          'A nota salva está fora do intervalo do formulário.',
        );
      }
      setState(() {
        _rating = rating;
        _comment.text = review?.comment ?? '';
      });
    } catch (error) {
      debugPrint('Falha ao carregar avaliação pessoal: $error');
      if (!mounted) return;

      setState(() {
        _myReviewError = 'Não foi possível carregar sua avaliação.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingMyReview = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved() async {
    setState(() => _busy = true);
    try {
      await _api.toggleSaved(widget.content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua lista foi atualizada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atualizar sua lista.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveReview() async {
    setState(() => _busy = true);
    try {
      await _api.saveReview(widget.content, _rating, _comment.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avaliação salva!')));
      await _checkCommunityReviews();
    } catch (error, stackTrace) {
      debugPrint('falha: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a avaliação.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildCommunitySection(List<Map<String, dynamic>> reviews) {
    if (_loadingCommunity || _loadingMyReview) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_communityError != null || _myReviewError != null) {
      return const Text('Carregue as avaliações tentando novamente');
    }
    if (reviews.isEmpty) {
      return const Text('Ainda não há avaliações de outras pessoas.');
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: reviews.map((item) {
        final author = item['nomeUsuario'] as String?;
        final comment = item['comentario'] as String? ?? '';
        final rating = (item['nota'] as num).toDouble();

        return CommunityReviewCard(
          author: author,
          rating: rating,
          comment: comment,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final saved = _api.isSaved(content);
    final review = _api.reviewFor(content);
    final otherReviews = _communityReviews
        .where((item) => item['id'] != review?.id)
        .toList();
    final totalReviews =
        (_reviewSummary?['totalAvaliacoes'] as num?)?.toInt() ?? 0;
    final communityAverage = _reviewSummary?['media'] as num?;
    final canEditReview = !_busy && !_loadingMyReview && _myReviewError == null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ContentHeader(content: content),

            Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    content['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${content['year']}  •  ${content['genre']}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Icon(
                        HugeIconsSolid.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      Text('TMDB: ${content['score']}'),
                    ],
                  ),
                  if (content['overview'] != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      content['overview']!,
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_loadingCommunity)
                    const LinearProgressIndicator()
                  else if (_communityError != null)
                    Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(_communityError!),
                        TextButton(
                          onPressed: _checkCommunityReviews,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    )
                  else
                    Text(
                      totalReviews == 0
                          ? 'TVScore: ainda sem avaliações'
                          : 'TVScore: ${communityAverage?.toStringAsFixed(1) ?? '—'}/10'
                                ' • $totalReviews '
                                '${totalReviews == 1 ? 'avaliação' : 'avaliações'}',
                    ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _toggleSaved,
                    icon: Icon(
                      saved
                          ? HugeIconsSolid.favourite
                          : HugeIconsStroke.favourite,
                    ),
                    label: Text(
                      saved
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                    ),
                  ),
                  
                  if (content['type'] == 'TV') ...[
                    const SizedBox(height: 24),
                    const EpisodeRatingsGrid(),
                    const SizedBox(height: 24),
                  ]
                  else
                  const SizedBox(height: 24),

                  if (_loadingMyReview)
                    const LinearProgressIndicator()
                  else if (_myReviewError != null)
                    Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(_myReviewError!),
                        TextButton(
                          onPressed: _loadMyReview,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ReviewForm(
                    isEditing: review != null,
                    rating: _rating,
                    commentController: _comment,
                    enabled: canEditReview,
                    isSaving: _busy,
                    onRatingChanged: (value) => setState(() => _rating = value),
                    onSave: _saveReview,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Avaliações da comunidade',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildCommunitySection(otherReviews),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
