import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import '../core/app_haptics.dart';
import '../core/app_routes.dart';
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
    this.contentLoaded = false,
    this.heroTag,
    this.onFavoriteChanged,
  });

  final Map<String, String> content;
  final bool contentLoaded;
  final Object? heroTag;
  final VoidCallback? onFavoriteChanged;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  final _api = ApiService();
  final _episodesKey = GlobalKey();
  late final TextEditingController _comment;
  late Widget _whereToWatch;
  Future<Map<String, String>>? _details;
  late double _rating;
  bool _busy = false;
  bool _loadingFavorites = false;
  bool _favoritesReady = false;
  Map<String, dynamic>? _reviewSummary;
  bool _loadingSummary = true;
  String? _summaryError;
  bool _loadingCommunity = true;
  String? _communityError;
  bool _loadingMyReview = true;
  String? _myReviewError;
  List<Map<String, dynamic>> _communityReviews = [];
  int _communityTotal = 0;
  bool _openingLogin = false;
  int _summaryRequest = 0;
  int _communityRequest = 0;
  int _personalRequest = 0;
  @override
  void initState() {
    super.initState();
    _loadDetails();
    _rating = 8.0;
    _comment = TextEditingController();
    ApiService.sessionRevision.addListener(_sessionChanged);
    ApiService.savedContentsRevision.addListener(_favoritesChanged);
    if (ApiService.hasSession) {
      _loadMyReview();
      _loadFavorites();
    }
    _checkCommunityReviews();
  }

  void _sessionChanged() {
    if (!mounted) return;
    _personalRequest++;
    setState(() {
      _comment.clear();
      _rating = 8.0;
      _busy = false;
      _favoritesReady = false;
      _loadingFavorites = false;
      _myReviewError = null;
      _loadingMyReview = ApiService.hasSession;
    });
    if (ApiService.hasSession) {
      _loadMyReview();
      _loadFavorites();
    }
  }

  void _favoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadFavorites() async {
    final session = ApiService.sessionRevision.value;
    bool isCurrent() => mounted && session == ApiService.sessionRevision.value;
    setState(() => _loadingFavorites = true);
    try {
      await _api.ensureFavoritesLoaded();
      if (isCurrent()) setState(() => _favoritesReady = true);
    } catch (_) {
      if (mounted && isCurrent()) {
        TvScoreSnackbar.error(
          context,
          'Não foi possível carregar seus favoritos. Toque no coração para tentar novamente.',
        );
      }
    } finally {
      if (isCurrent()) setState(() => _loadingFavorites = false);
    }
  }

  @override
  void didUpdateWidget(covariant DetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.contentKey != widget.content.contentKey ||
        oldWidget.contentLoaded != widget.contentLoaded ||
        oldWidget.content['ondeAssistir'] != widget.content['ondeAssistir'] ||
        oldWidget.content['backdrop_path'] != widget.content['backdrop_path']) {
      _loadDetails();
    }
  }

  void _loadDetails() {
    final content = widget.content;
    _details = null;
    if (!widget.contentLoaded &&
        (content['ondeAssistir'] == null ||
            (content['backdrop_path'] ?? '').isEmpty)) {
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
    await Future.wait([_loadReviewSummary(), _loadCommunityReviews()]);
  }

  Future<void> _loadReviewSummary() async {
    final request = ++_summaryRequest;
    bool isCurrent() => mounted && request == _summaryRequest;
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final reference = widget.content.apiReference;
      final summary = await _api.getContentReviewSummary(
        reference.id,
        reference.type,
      );
      if (isCurrent()) setState(() => _reviewSummary = summary);
    } catch (_) {
      if (isCurrent()) {
        setState(
          () => _summaryError = 'Não foi possível carregar a média TVScore.',
        );
      }
    } finally {
      if (isCurrent()) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadCommunityReviews() async {
    final request = ++_communityRequest;
    bool isCurrent() => mounted && request == _communityRequest;
    setState(() {
      _loadingCommunity = true;
      _communityError = null;
    });

    try {
      final reference = widget.content.apiReference;
      final reviews = await _api.getContentReviewsPage(
        reference.id,
        reference.type,
        size: 3,
      );

      if (!isCurrent()) return;
      setState(() {
        _communityReviews = reviews.reviews;
        _communityTotal = reviews.totalElements;
      });
    } catch (error) {
      if (!isCurrent()) return;
      setState(() {
        _communityError = error is CommunityReviewsRestricted
            ? CommunityReviewsRestricted.message
            : 'Não foi possível carregar as avaliações.';
      });
    } finally {
      if (isCurrent()) {
        setState(() {
          _loadingCommunity = false;
        });
      }
    }
  }

  Future<void> _signInToReview() async {
    if (_openingLogin) return;
    _openingLogin = true;
    try {
      final authenticated = await Navigator.pushNamed<dynamic>(
        context,
        AppRoutes.login,
        arguments: AppRoutes.returnToOriginArguments,
      );
      if (!mounted || authenticated != true || !ApiService.hasSession) return;
      // The details route stays in the stack, including its content and scroll.
      // Authentication only unlocks the form; saving still requires an explicit tap.
      await _checkCommunityReviews();
    } finally {
      _openingLogin = false;
    }
  }

  Future<void> _loadMyReview() async {
    final request = ++_personalRequest;
    final session = ApiService.sessionRevision.value;
    bool isCurrent() =>
        mounted &&
        request == _personalRequest &&
        session == ApiService.sessionRevision.value;
    setState(() {
      _loadingMyReview = true;
      _myReviewError = null;
    });

    try {
      await _api.loadMyReviewFor(widget.content);
      if (!isCurrent()) return;

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
      if (!isCurrent()) return;

      setState(() {
        _myReviewError = 'Não foi possível carregar sua avaliação.';
      });
    } finally {
      if (isCurrent()) {
        setState(() {
          _loadingMyReview = false;
        });
      }
    }
  }

  @override
  void dispose() {
    ApiService.sessionRevision.removeListener(_sessionChanged);
    ApiService.savedContentsRevision.removeListener(_favoritesChanged);
    _comment.dispose();
    super.dispose();
  }

  Future<void> _toggleSaved() async {
    final session = ApiService.sessionRevision.value;
    bool isCurrent() => mounted && session == ApiService.sessionRevision.value;
    final wasSaved = _api.isSaved(widget.content);
    setState(() => _busy = true);
    try {
      await _api.setSaved(widget.content, !wasSaved);
      if (!mounted || !isCurrent()) return;
      AppHaptics.confirmation();
      widget.onFavoriteChanged?.call();
      TvScoreSnackbar.info(
        context,
        wasSaved ? 'Removido dos favoritos.' : 'Adicionado aos favoritos.',
      );
    } catch (_) {
      if (!mounted || !isCurrent()) return;
      AppHaptics.error();
      TvScoreSnackbar.error(
        context,
        'Não foi possível atualizar seus favoritos.',
      );
    } finally {
      if (isCurrent()) setState(() => _busy = false);
    }
  }

  Future<void> _saveReview() async {
    final session = ApiService.sessionRevision.value;
    bool isCurrent() => mounted && session == ApiService.sessionRevision.value;
    setState(() => _busy = true);
    try {
      await _api.saveReview(widget.content, _rating, _comment.text);
      if (!mounted || !isCurrent()) return;
      AppHaptics.confirmation();
      TvScoreSnackbar.success(context, 'Sua avaliação foi salva.');
      await _checkCommunityReviews();
    } catch (error, stackTrace) {
      debugPrint('falha: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || !isCurrent()) return;
      AppHaptics.error();
      TvScoreSnackbar.error(
        context,
        'Não foi possível salvar sua avaliação. Tente novamente.',
      );
    } finally {
      if (isCurrent()) setState(() => _busy = false);
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
                  constraints:
                      AppBreakpoints.supportsWidePages &&
                          AppBreakpoints.isDesktop(
                            MediaQuery.sizeOf(context).width,
                          )
                      ? const BoxConstraints(maxWidth: 720, maxHeight: 760)
                      : null,
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
    final hasSession = ApiService.hasSession;
    final desktop =
        AppBreakpoints.supportsWidePages &&
        AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final saved = _api.isSaved(content);
    final review = _api.reviewFor(content);
    final totalReviews =
        (_reviewSummary?['totalAvaliacoes'] as num?)?.toInt() ?? 0;
    final communityAverage = _reviewSummary?['media'] as num?;
    final canEditReview = !_busy && !_loadingMyReview && _myReviewError == null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final metadataStyle = TextStyle(color: colors.onSurfaceVariant);
    final year = content['year']?.trim() ?? '';
    final recommendationReason = content['recommendation_reason']?.trim();
    final genres = (content['genre'] ?? '')
        .split('•')
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty && genre != 'não informado')
        .toList();
    final genreFill = theme.brightness == Brightness.dark
        ? colors.secondaryContainer.withValues(alpha: .34)
        : colors.primaryContainer.withValues(alpha: .32);
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
              Column(
                children: [
                  ContentHeader(
                    content: content,
                    heroTag: widget.heroTag,
                    isSaved: saved,
                    onFavoritePressed: !hasSession || _busy || _loadingFavorites
                        ? null
                        : _favoritesReady
                        ? _toggleSaved
                        : _loadFavorites,
                    information: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (year.isNotEmpty) Text(year, style: metadataStyle),
                        if (genres.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              for (final genre in genres)
                                DecoratedBox(
                                  decoration: ShapeDecoration(
                                    color: genreFill,
                                    shape: StadiumBorder(
                                      side: BorderSide(
                                        color: colors.outlineVariant.withValues(
                                          alpha: .65,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      genre,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
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
                            if (_loadingSummary)
                              const SkeletonBlock(width: 110, height: 15)
                            else if (_summaryError != null)
                              Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(_summaryError!),
                                  TextButton(
                                    onPressed: _loadReviewSummary,
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
                        if (recommendationReason != null &&
                            recommendationReason.isNotEmpty)
                          ExpansionTile(
                            key: ValueKey((
                              content.contentKey,
                              recommendationReason,
                            )),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 8),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            leading: const Icon(
                              HugeIconsSolid.sparkles,
                              size: 16,
                            ),
                            title: Text(
                              'Recomendado para você',
                              style: theme.textTheme.labelLarge,
                            ),
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              Text(recommendationReason, style: metadataStyle),
                            ],
                          )
                        else
                          const SizedBox(height: 16),
                        _whereToWatch,
                        if (content['overview'] != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            content['overview']!,
                            style: const TextStyle(height: 1.6),
                          ),
                        ],
                        if (desktop && content['type'] == 'TV') ...[
                          const SizedBox(height: 24),
                          EpisodePanel(
                            key: _episodesKey,
                            seriesId: int.parse(content['id']!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: desktop ? 960 : double.infinity,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: desktop ? 32 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: desktop
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.start,
                          children: [
                            if (!desktop && content['type'] == 'TV') ...[
                              const SizedBox(height: 24),
                              EpisodePanel(
                                key: _episodesKey,
                                seriesId: int.parse(content['id']!),
                              ),
                            ],
                            if (hasSession) ...[
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
                            ] else ...[
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _signInToReview,
                                child: const Text('Entrar para avaliar'),
                              ),
                            ],
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
