import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';

import '../services/api_services.dart';

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
      final summary = await _api.getContentReviewSummary(id, type);
      final reviews = await _api.getContentReviews(id, type);

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

        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  children: [
                    Text(
                      author == null || author.trim().isEmpty
                          ? 'Usuário'
                          : author,
                    ),
                    SizedBox(width: 8,),
                    Text('•'),
                    SizedBox(width: 8,),
                    const Icon(
                      HugeIconsSolid.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text('${rating.toStringAsFixed(1)}/10'),
                  ],
                ),
                if (comment.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(comment),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final backdrop = content['backdrop_path'];
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
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
            Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 350 + (MediaQuery.of(context).padding.top),
                    child: Image.network(
                      backdrop ?? '',
                      fit: BoxFit.fitHeight,
                      alignment: const Alignment(0.3, 0),
                      errorBuilder: (_, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            backgroundColor.withValues(alpha: 0.05),
                            backgroundColor.withValues(alpha: 0.15),
                            backgroundColor.withValues(alpha: 0.45),
                            backgroundColor.withValues(alpha: 0.8),
                            backgroundColor.withValues(alpha: 0.9),
                            backgroundColor,
                          ],
                          stops: const [0, 0.5, 0.65, 0.85, 0.90, 0.95],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            backgroundColor.withValues(alpha: 0),
                            backgroundColor.withValues(alpha: 0.15),
                            backgroundColor.withValues(alpha: 0.65),
                            backgroundColor,
                          ],
                          stops: const [0, 0.75, 0.90, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    width: 125,
                    height: 170,
                    child: ContentPoster(content: content),
                  ),
                ],
              ),
            ),

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
                  Row(
                    children: [
                      Text(
                        '${content['year']}  •  ${content['genre']}  •  ',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Icon(
                        HugeIconsSolid.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
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
                  const SizedBox(height: 28),
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
                  Text(
                    review == null ? 'Sua avaliação' : 'Editar sua avaliação',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua nota: $_rating / 10',
                    style: const TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                  Slider(
                    value: _rating,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: '$_rating',
                    onChanged: canEditReview
                        ? (value) => setState(() => _rating = value)
                        : null,
                  ),
                  TextField(
                    controller: _comment,
                    enabled: canEditReview,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Comentário (opcional)',
                      hintText: 'O que você achou desse título?',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: !canEditReview ? null : _saveReview,
                    icon: const Icon(Icons.star_outline),
                    label: Text(_busy ? 'Salvando...' : 'Salvar avaliação'),
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
