import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_haptics.dart';
import '../models/content_metadata.dart';
import '../models/review.dart';
import '../services/api_services.dart';
import '../widgets/community_review_card.dart';
import '../widgets/community_reviews_sheet.dart';
import '../widgets/content_header.dart';
import '../widgets/details_system_ui.dart';
import '../widgets/episode_panel.dart';
import '../widgets/review_form.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/tv_score_snackbar.dart';
import '../widgets/where_to_watch.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({
    super.key,
    required this.content,
    this.heroTag,
    this.onFavoriteChanged,
  });

  final Map<String, String> content;
  final Object? heroTag;
  final VoidCallback? onFavoriteChanged;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _api = ApiService();
  late final TextEditingController _comment;
  late Widget _whereToWatch;
  Future<Map<String, String>>? _details;
  late double _rating;
  bool _busy = false;
  Map<String, dynamic>? _reviewSummary;
  bool _loadingCommunity = true;
  String? _communityError;
  bool _loadingMyReview = true;
  String? _myReviewError;
  List<Map<String, dynamic>> _communityReviews = [];
  int _communityTotal = 0;
  @override
  void initState() {
    super.initState();
    _loadDetails();
    _rating = 8.0;
    _comment = TextEditingController();
    _loadMyReview();
    _checkCommunityReviews();
  }

  @override
  void didUpdateWidget(covariant DetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.contentKey != widget.content.contentKey ||
        oldWidget.content['ondeAssistir'] != widget.content['ondeAssistir'] ||
        oldWidget.content['backdrop_path'] != widget.content['backdrop_path']) {
      _loadDetails();
    }
  }

  void _loadDetails() {
    final content = widget.content;
    _details = null;
    if (content['ondeAssistir'] == null ||
        (content['backdrop_path'] ?? '').isEmpty) {
      final reference = content.apiReference;
      _details = _api.getContent(reference.id, reference.type);
    }
    _whereToWatch = _buildWhereToWatch();
  }

  Widget _buildWhereToWatch() {
    final availability = widget.content['ondeAssistir'];
    if (availability != null) return WhereToWatch(availability);
    return FutureBuilder<Map<String, String>>(
      future: _details,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SkeletonBlock(height: 48);
        }
        return WhereToWatch(snapshot.data?['ondeAssistir']);
      },
    );
  }

  Future<void> _checkCommunityReviews() async {
    setState(() {
      _loadingCommunity = true;
      _communityError = null;
    });

    try {
      final reference = widget.content.apiReference;
      final (summary, reviews) = await (
        _api.getContentReviewSummary(reference.id, reference.type),
        _api.getContentReviewsPage(reference.id, reference.type, size: 3),
      ).wait;

      if (!mounted) return;
      setState(() {
        _reviewSummary = summary;
        _communityReviews = reviews.reviews;
        _communityTotal = reviews.totalElements;
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

      if (!Review.isValidRating(rating)) {
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
    final wasSaved = _api.isSaved(widget.content);
    setState(() => _busy = true);
    try {
      await _api.toggleSaved(widget.content);
      if (!mounted) return;
      AppHaptics.confirmation();
      widget.onFavoriteChanged?.call();
      TvScoreSnackbar.info(
        context,
        wasSaved ? 'Removido dos favoritos.' : 'Adicionado aos favoritos.',
      );
    } catch (_) {
      if (!mounted) return;
      AppHaptics.error();
      TvScoreSnackbar.error(
        context,
        'Não foi possível atualizar seus favoritos.',
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
      AppHaptics.confirmation();
      TvScoreSnackbar.success(context, 'Sua avaliação foi salva.');
      await _checkCommunityReviews();
    } catch (error, stackTrace) {
      debugPrint('falha: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      AppHaptics.error();
      TvScoreSnackbar.error(
        context,
        'Não foi possível salvar sua avaliação. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildCommunitySection() {
    if (_loadingCommunity) {
      return const SkeletonShimmer(
        child: Column(
          children: [
            SkeletonBlock(height: 96),
            SizedBox(height: 12),
            SkeletonBlock(height: 96),
          ],
        ),
      );
    }
    if (_communityError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_communityError!),
          TextButton(
            onPressed: _checkCommunityReviews,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    if (_communityReviews.isEmpty) {
      return const Text('Ainda não há avaliações para este título.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final review in _communityReviews)
          CommunityReviewCard.fromJson(review),
        if (_communityTotal > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                final reference = widget.content.apiReference;
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommunityReviewsSheet(
                    contentId: reference.id,
                    type: reference.type,
                  ),
                );
              },
              child: const Text('Ver todas as avaliações'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    if ((content['backdrop_path'] ?? '').isNotEmpty) {
      return _buildDetails(context, content);
    }
    return FutureBuilder<Map<String, String>>(
      key: ValueKey(content.contentKey),
      future: _details,
      builder: (context, snapshot) => _buildDetails(context, {
        ...content,
        'backdrop_path': snapshot.data?['backdrop_path'] ?? '',
      }),
    );
  }

  Widget _buildDetails(BuildContext context, Map<String, String> content) {
    final saved = _api.isSaved(content);
    final review = _api.reviewFor(content);
    final totalReviews =
        (_reviewSummary?['totalAvaliacoes'] as num?)?.toInt() ?? 0;
    final communityAverage = _reviewSummary?['media'] as num?;
    final canEditReview = !_busy && !_loadingMyReview && _myReviewError == null;
    final metadataStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final year = content['year']?.trim() ?? '';
    final genres = content['genre']?.trim() ?? '';
    return DetailsSystemUi(
      backdrop: content['backdrop_path'],
      builder: (context, systemUi) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          systemOverlayStyle: systemUi,
          // A mixed backdrop needs a scrim so both ends of the status bar stay legible.
          flexibleSpace: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.paddingOf(context).top,
              child: ColoredBox(
                color: systemUi.statusBarIconBrightness == Brightness.dark
                    ? Colors.white.withValues(alpha: .62)
                    : Colors.black.withValues(alpha: .55),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          leading: Theme.of(context).brightness == Brightness.light
              ? Center(
                  child: BackButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: .68),
                    ),
                  ),
                )
              : null,
          scrolledUnderElevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ContentHeader(
                content: content,
                heroTag: widget.heroTag,
                isSaved: saved,
                onFavoritePressed: _busy ? null : _toggleSaved,
              ),

              Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      content['title'] ?? '',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (year.isNotEmpty) year,
                        genres.isEmpty ? 'Gêneros não informados' : genres,
                      ].join(' • '),
                      style: metadataStyle,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              HugeIconsSolid.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'TMDB:\u00a0${content['score']}/10',
                                style: metadataStyle,
                              ),
                            ),
                          ],
                        ),
                        if (_loadingCommunity)
                          const SkeletonBlock(width: 110, height: 15)
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'lib/assets/logoSemTexto.svg',
                                height: 15,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  totalReviews == 0
                                      ? 'TVScore: sem avaliações'
                                      : 'TVScore:\u00a0${communityAverage?.toStringAsFixed(1) ?? '—'}/10',
                                  style: metadataStyle,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _whereToWatch,
                    if (content['overview'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        content['overview']!,
                        style: const TextStyle(height: 1.6),
                      ),
                    ],

                    if (content['type'] == 'TV') ...[
                      const SizedBox(height: 24),
                      EpisodePanel(seriesId: int.parse(content['id']!)),
                    ],
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
                      onRatingChanged: (value) {
                        if (value == _rating) return;
                        AppHaptics.selection();
                        setState(() => _rating = value);
                      },
                      onSave: _saveReview,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Avaliações da comunidade',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCommunitySection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
