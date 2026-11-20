import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import '../core/app_routes.dart';
import '../core/light_logo_color_mapper.dart';
import '../models/content_metadata.dart';
import '../models/recommendations.dart';
import '../services/api_services.dart';
import '../widgets/content_carousel.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/top_rated_carousel.dart';
import '../widgets/trending_carousel.dart';
import '../widgets/tv_score_segmented_control.dart';
import '../widgets/tv_score_snackbar.dart';

enum HomeSectionType { personalized, trending, genre, discover }

typedef HomeSection = ({
  HomeSectionType type,
  String heroSection,
  String title,
  IconData icon,
  List<Map<String, String>> contents,
  String? nextPageGenre,
});

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.bottomPadding = 12});

  final double bottomPadding;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<HomeSection>> _sections;
  late Future<List<Map<String, dynamic>>> _availableGenres;
  late Future<List<Map<String, String>>> _trending;
  late Future<List<Map<String, String>>> _topRated;
  Future<void>? _recommendationLoad;
  final _recommendationYears = <(String?, String?), Future<String>>{};
  List<Map<String, String>> _forYouRecommendations = const [];
  Set<(String?, String?)> _recommended = const {};
  List<HomeSection>? _catalogSections;
  List<Map<String, String>>? _highlights;
  final _extraGenreContents = <String, List<Map<String, String>>>{};
  Map<String, List<Map<String, String>>> _distributed = const {};
  bool _canChangeTrendingFilter = false;
  bool _recommendationsPending = false;
  bool _catalogPending = false;
  bool _trendingPending = false;
  bool _extraPageRequested = false;
  bool _recommendationsReloadQueued = false;
  String _trendingType = 'ALL';
  String _topRatedType = 'ALL';
  String _personalizedType = 'ALL';
  static const _personalizedPosterScale = 1.1;

  @override
  void initState() {
    super.initState();
    _availableGenres = ApiService().getAvailableGenres();
    _reloadCatalog();
    _reloadTrending();
    _topRated = ApiService().getTopRatedContents(_topRatedType);
    _loadRecommendations();
    ApiService.contentPreferencesRevision.addListener(_reloadPreferences);
    ApiService.recommendationsRevision.addListener(_recommendationsInvalidated);
    ApiService.sessionRevision.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (!mounted) return;
    setState(() {
      _recommendationLoad = null;
      _recommendationYears.clear();
      _recommended = const {};
      _forYouRecommendations = const [];
      _catalogSections = null;
      _extraGenreContents.clear();
      _reloadCatalog();
      _loadRecommendations();
    });
  }

  void _reloadPreferences() {
    setState(_reloadCatalog);
  }

  void _recommendationsInvalidated() {
    if (_recommendationsReloadQueued) return;
    _recommendationsReloadQueued = true;
    Future<void>.microtask(() {
      _recommendationsReloadQueued = false;
      if (mounted) _loadRecommendations();
    });
  }

  void _reloadCatalog() {
    final token = ApiService.token;
    final request = _sections = _loadSections();
    _catalogPending = true;
    void complete(List<HomeSection>? sections) {
      if (!mounted || !identical(_sections, request)) return;
      setState(() {
        _catalogPending = false;
        _catalogSections = ApiService.token == token ? sections : const [];
        _extraPageRequested = false;
        _extraGenreContents.clear();
        _distributeContents();
      });
      _fillEmptyGenre();
    }

    request.then(complete, onError: (Object _) => complete(null));
  }

  void _reloadTrending() {
    final request = _trending = ApiService().getHighlights();
    _trendingPending = true;
    void complete(List<Map<String, String>> contents) {
      if (!mounted || !identical(_trending, request)) return;
      setState(() {
        _trendingPending = false;
        _highlights = contents;
        _distributeContents();
      });
      _fillEmptyGenre();
    }

    request.then(complete, onError: (Object _) => complete(const []));
  }

  void _distributeContents() {
    final used = <(String?, String?)>{};
    final sections = _catalogSections ?? const <HomeSection>[];
    final highlights = _highlights ?? const <Map<String, String>>[];
    List<Map<String, String>> allocate(
      Iterable<Map<String, String>> candidates, {
      String type = 'ALL',
      int? limit,
    }) {
      final filtered = candidates
          .where((item) => type == 'ALL' || item['type'] == type)
          .where((item) => used.add(item.contentKey));
      return (limit == null ? filtered : filtered.take(limit)).toList();
    }

    final fallback = sections
        .where((section) => section.type == HomeSectionType.personalized)
        .firstOrNull
        ?.contents;
    final personalized = _forYouRecommendations.isNotEmpty
        ? _forYouRecommendations
        : fallback != null && fallback.isNotEmpty
        ? fallback
        : _catalogSections == null
        ? const <Map<String, String>>[]
        : highlights;
    final forYou = ApiService.hasSession
        ? allocate(
            personalized,
            type: _personalizedType,
            limit: _forYouRecommendations.isEmpty ? 12 : null,
          )
        : <Map<String, String>>[];
    _canChangeTrendingFilter = highlights.any(
      (item) => !used.contains(item.contentKey),
    );
    _distributed = {
      'personalized': forYou,
      'trending': allocate(
        _prioritizeTrending(highlights),
        type: _trendingType,
      ),
      for (final section in sections)
        if (section.type != HomeSectionType.personalized)
          section.heroSection: allocate([
            ...section.contents,
            ...?_extraGenreContents[section.heroSection],
          ]),
    };
  }

  Future<void> _fillEmptyGenre() async {
    if (_extraPageRequested ||
        _catalogPending ||
        _trendingPending ||
        _recommendationsPending) {
      return;
    }
    final section = _catalogSections
        ?.where(
          (section) =>
              section.nextPageGenre != null &&
              _distributed[section.heroSection]?.isEmpty == true,
        )
        .firstOrNull;
    if (section == null) return;
    _extraPageRequested = true;
    final catalog = _sections;
    final token = ApiService.token;
    try {
      final page = await ApiService().getGenrePage(
        section.nextPageGenre!,
        page: 2,
      );
      if (!mounted ||
          !identical(_sections, catalog) ||
          ApiService.token != token) {
        return;
      }
      setState(() {
        _extraGenreContents[section.heroSection] = page.contents;
        _distributeContents();
      });
    } catch (_) {
      // An optional catalog page must not interrupt the Home.
    }
  }

  Future<void> _loadRecommendations({bool refresh = false}) {
    final token = ApiService.token;
    if (!ApiService.hasSession) {
      _recommendationLoad = null;
      _recommended = const {};
      _forYouRecommendations = const [];
      _recommendationsPending = false;
      _distributeContents();
      return Future.value();
    }
    _recommendationsPending = true;
    final api = ApiService();
    late final Future<void> load;
    Future<List<Recommendation>> read(
      Future<Recommendations> Function({bool refresh}) request,
    ) async {
      try {
        return (await request(refresh: refresh)).items;
      } on RecommendationException catch (error) {
        if (!refresh &&
            const {
              RecommendationFailure.unavailable,
              RecommendationFailure.timeout,
              RecommendationFailure.requestFailed,
            }.contains(error.failure)) {
          await Future<void>.delayed(const Duration(seconds: 1));
          if (mounted &&
              identical(_recommendationLoad, load) &&
              ApiService.token == token) {
            try {
              return (await request()).items;
            } on RecommendationException {
              return const [];
            }
          }
        }
        return const [];
      }
    }

    load =
        Future.wait([
          read(api.getMovieRecommendations),
          read(api.getSeriesRecommendations),
        ]).then((results) async {
          if (!mounted || !identical(_recommendationLoad, load)) return;
          _recommendationsPending = false;
          if (ApiService.token != token) {
            setState(() {
              _recommended = const {};
              _forYouRecommendations = const [];
              _catalogSections = const [];
              _extraGenreContents.clear();
              _distributeContents();
            });
            return;
          }
          final (movies, series) = (results[0], results[1]);
          final seen = <(String?, String?)>{};
          final contents = [
            for (var i = 0; i < movies.length || i < series.length; i++)
              for (final list in [movies, series])
                if (i < list.length && seen.add(list[i].content.contentKey))
                  {
                    ...list[i].content,
                    if (list[i].rankingScore case final score?)
                      'recommendation_score': score.toString(),
                    if (list[i].reason case final reason?
                        when reason.trim().isNotEmpty)
                      'recommendation_reason': reason,
                  },
          ];
          setState(() {
            _recommended = seen;
            _forYouRecommendations = contents;
            _distributeContents();
          });
          _fillEmptyGenre();
          final catalog = <(String?, String?), String>{};
          Future<void> collect(Future<List<Map<String, String>>> source) async {
            try {
              for (final content in await source) {
                final year = content['year'] ?? '';
                if (year.isNotEmpty) catalog[content.contentKey] = year;
              }
            } catch (_) {
              // Public metadata is optional; recommendation order is unchanged.
            }
          }

          await Future.wait([
            collect(
              _sections.then(
                (sections) => [
                  for (final section in sections) ...section.contents,
                ],
              ),
            ),
            collect(_trending),
            collect(_topRated),
          ]);
          if (!mounted || !identical(_recommendationLoad, load)) return;
          final years = <(String?, String?), String>{};
          await Future.wait([
            for (final item in results.expand((items) => items))
              if ((item.content['year'] ?? '').isEmpty)
                () async {
                  final key = item.content.contentKey;
                  years[key] =
                      catalog[key] ??
                      await _recommendationYears.putIfAbsent(key, () async {
                        try {
                          final reference = item.identity;
                          final content = await api.getContent(
                            reference.id,
                            reference.type,
                          );
                          return content['year'] ?? '';
                        } catch (_) {
                          _recommendationYears.remove(key);
                          return '';
                        }
                      });
                }(),
          ]);
          if (!mounted || !identical(_recommendationLoad, load)) return;
          setState(() {
            _forYouRecommendations = [
              for (final content in _forYouRecommendations)
                {...content, 'year': ?years[content.contentKey]},
            ];
            _distributeContents();
          });
        });
    return _recommendationLoad = load;
  }

  bool _isRecommended(Map<String, String> content) =>
      _recommended.contains(content.contentKey);

  List<Map<String, String>> _prioritizeMatches(
    List<Map<String, String>> contents,
  ) => _recommended.isEmpty
      ? contents
      : [
          ...contents.where(_isRecommended),
          ...contents.where((content) => !_isRecommended(content)),
        ];

  List<Map<String, String>> _prioritizeTrending(
    List<Map<String, String>> contents,
  ) {
    if (_recommended.isEmpty) return contents;
    final ordered = contents.toList();
    // Limit the recommendation signal to one neighboring trend rank.
    for (var i = 0; i + 1 < ordered.length; i += 2) {
      final (first, second) = (ordered[i], ordered[i + 1]);
      if (first['type'] == second['type'] &&
          !_isRecommended(first) &&
          _isRecommended(second)) {
        ordered[i] = second;
        ordered[i + 1] = first;
      }
    }
    return ordered;
  }

  List<Map<String, String>> _prioritizeRated(
    List<Map<String, String>> contents,
  ) {
    if (_recommended.isEmpty) return contents;
    final ordered = <Map<String, String>>[];
    for (var start = 0; start < contents.length;) {
      var end = start + 1;
      while (end < contents.length &&
          contents[end]['score'] == contents[start]['score']) {
        end++;
      }
      ordered.addAll(_prioritizeMatches(contents.sublist(start, end)));
      start = end;
    }
    return ordered;
  }

  @override
  void dispose() {
    ApiService.sessionRevision.removeListener(_sessionChanged);
    ApiService.contentPreferencesRevision.removeListener(_reloadPreferences);
    ApiService.recommendationsRevision.removeListener(
      _recommendationsInvalidated,
    );
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<HomeSection>> _loadSections() async {
    final api = ApiService();

    final (available, preferred) = await (
      _availableGenres,
      !ApiService.hasSession
          ? Future.value(<Map<String, dynamic>>[])
          : api.getPreferredGenres(),
    ).wait;

    final preferredCodes = preferred
        .map((genre) => genre['codigo'] as String)
        .toSet();

    final preferredGenres = available
        .where((genre) => preferredCodes.contains(genre['codigo']))
        .toList();

    final otherGenres = available
        .where((genre) => !preferredCodes.contains(genre['codigo']))
        .toList();

    final discoverGenre = otherGenres.firstOrNull;

    final codesToLoad = <String>{
      ...preferredGenres.map((genre) => genre['codigo'] as String),
      if (discoverGenre != null) discoverGenre['codigo'] as String,
    };

    final pages = Map.fromEntries(
      await Future.wait(
        codesToLoad.map((code) async {
          try {
            return MapEntry(code, await api.getGenrePage(code));
          } catch (_) {
            return MapEntry(code, (
              contents: const <Map<String, String>>[],
              hasNextPage: false,
            ));
          }
        }),
      ),
    );

    final sections = <HomeSection>[];

    if (preferredGenres.isNotEmpty) {
      final lists = preferredGenres
          .map(
            (genre) =>
                pages[genre['codigo']]?.contents ?? <Map<String, String>>[],
          )
          .toList();
      final forYou = <Map<String, String>>[];
      final seen = <(String?, String?)>{};
      for (var index = 0; ; index++) {
        var added = false;
        for (final list in lists) {
          if (index < list.length) {
            final content = list[index];
            if (seen.add(content.contentKey)) forYou.add(content);
            added = true;
          }
        }
        if (!added) break;
      }

      sections.add((
        type: HomeSectionType.personalized,
        heroSection: 'personalized',
        title: 'Para você',
        icon: HugeIconsSolid.sparkles,
        contents: forYou,
        nextPageGenre: null,
      ));
    }

    for (final genre in preferredGenres) {
      sections.add((
        type: HomeSectionType.genre,
        heroSection: 'genre:${genre['codigo']}',
        title: genre['nome'] as String,
        icon: genreIcon(genre['codigo'] as String),
        contents: pages[genre['codigo']]?.contents ?? [],
        nextPageGenre: pages[genre['codigo']]?.hasNextPage == true
            ? genre['codigo'] as String
            : null,
      ));
    }

    if (discoverGenre != null) {
      sections.add((
        type: HomeSectionType.discover,
        heroSection: 'discover:${discoverGenre['codigo']}',
        title: 'Descubra algo',
        icon: HugeIconsSolid.compass01,
        contents: pages[discoverGenre['codigo']]?.contents ?? [],
        nextPageGenre: pages[discoverGenre['codigo']]?.hasNextPage == true
            ? discoverGenre['codigo'] as String
            : null,
      ));
    }

    return sections;
  }

  Future<void> _refresh() async {
    _availableGenres = ApiService().getAvailableGenres();
    final topRated = ApiService().getTopRatedContents(_topRatedType);
    setState(() {
      _reloadCatalog();
      _reloadTrending();
      _topRated = topRated;
    });
    final recommendations = _loadRecommendations(refresh: true);
    try {
      await (_sections, _trending, topRated, recommendations).wait;
    } catch (error, stackTrace) {
      debugPrint('Erro ao atualizar Home: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        TvScoreSnackbar.error(
          context,
          'Não foi possível atualizar a página inicial. Tente novamente.',
        );
      }
    }
  }

  Widget _genreSections({
    bool personalized = false,
    bool firstGenre = false,
  }) => _KeepAliveSection(
    child: FutureBuilder<List<HomeSection>>(
      future: _sections,
      builder: (context, snapshot) {
        if (personalized && _forYouRecommendations.isNotEmpty) {
          return _personalizedCarousel(_distributed['personalized'] ?? []);
        }
        if (snapshot.hasError) {
          return personalized
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: () => setState(() {
                      _availableGenres = ApiService().getAvailableGenres();
                      _reloadCatalog();
                    }),
                    child: const Text(
                      'Não foi possível carregar os gêneros. Tentar novamente',
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }
        if (!snapshot.hasData) {
          return personalized
              ? const SkeletonCarousel(
                  featured: true,
                  showFilters: true,
                  posterScale: _personalizedPosterScale,
                )
              : const SizedBox.shrink();
        }
        if (personalized) {
          final fallback = snapshot.data!
              .where((section) => section.type == HomeSectionType.personalized)
              .firstOrNull
              ?.contents;
          if (fallback != null && fallback.isNotEmpty) {
            return _personalizedCarousel(_distributed['personalized'] ?? []);
          }
          return FutureBuilder(
            future: _trending,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SizedBox.shrink();
              if (!snapshot.hasData) {
                return const SkeletonCarousel(
                  featured: true,
                  showFilters: true,
                  posterScale: _personalizedPosterScale,
                );
              }
              if (snapshot.data!.isEmpty) return const SizedBox.shrink();
              return _personalizedCarousel(_distributed['personalized'] ?? []);
            },
          );
        }
        final sections = snapshot.data!;
        final leading = sections
            .where((section) => section.type == HomeSectionType.genre)
            .firstOrNull;
        return Column(
          children: [
            for (final section in sections)
              if (section.type != HomeSectionType.personalized &&
                  (section.heroSection == leading?.heroSection) == firstGenre)
                ContentCarousel(
                  key: ValueKey(section.heroSection),
                  onChanged: () => setState(() {}),
                  heroSection: section.heroSection,
                  icon: Icon(
                    section.icon,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: section.title,
                  contents: _distributed[section.heroSection] ?? [],
                ),
          ],
        );
      },
    ),
  );

  Widget _personalizedCarousel(List<Map<String, String>> contents) =>
      ContentCarousel(
        heroSection: 'personalized',
        icon: Icon(
          HugeIconsSolid.sparkles,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: 'Para você',
        contents: contents,
        featured: true,
        posterScale: _personalizedPosterScale,
        filters: TvScoreSegmentedControl<String>(
          textScale: _personalizedPosterScale,
          options: const {'ALL': 'Todos', 'MOVIE': 'Filmes', 'TV': 'Séries'},
          selectedValue: _personalizedType,
          onChanged: (value) => setState(() {
            _personalizedType = value;
            _distributeContents();
          }),
        ),
        onChanged: () => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 1360 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: desktop ? 12 : 0),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 12, bottom: widget.bottomPadding),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        if (desktop)
                          Text(
                            'Início',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          )
                        else
                          SvgPicture.asset(
                            'lib/assets/logoTvScore.svg',
                            height: 44,
                            colorMapper:
                                Theme.of(context).brightness == Brightness.light
                                ? const LightLogoColorMapper()
                                : null,
                          ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Pesquisar',
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.search);
                          },
                          icon: Icon(
                            HugeIconsSolid.search01,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (ApiService.hasSession) _genreSections(personalized: true),
                _KeepAliveSection(
                  child: FutureBuilder<List<Map<String, String>>>(
                    future: _trending,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return TextButton(
                          onPressed: () => setState(_reloadTrending),
                          child: const Text(
                            'Não foi possível carregar Em alta. Tentar novamente',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const SkeletonCarousel(showFilters: true);
                      }
                      return TrendingCarousel(
                        contents: _distributed['trending'] ?? [],
                        showWhenEmpty: _canChangeTrendingFilter,
                        selectedType: _trendingType,
                        onTypeSelected: (value) => setState(() {
                          _trendingType = value;
                          _distributeContents();
                        }),
                        onChanged: () => setState(() {}),
                        heroSection: 'trending',
                      );
                    },
                  ),
                ),
                _genreSections(firstGenre: true),
                _KeepAliveSection(
                  child: TopRatedCarousel(
                    heroSection: 'top-rated',
                    selectedType: _topRatedType,
                    onTypeSelected: (type) => setState(() {
                      _topRatedType = type;
                      _topRated = ApiService().getTopRatedContents(type);
                    }),
                    onRetry: () => setState(() {
                      _topRated = ApiService().getTopRatedContents(
                        _topRatedType,
                      );
                    }),
                    contents: _topRated,
                    orderContents: _prioritizeRated,
                    onChanged: () => setState(() {}),
                  ),
                ),
                _genreSections(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep completed futures and carousel filters when ListView recycles sections.
class _KeepAliveSection extends StatefulWidget {
  const _KeepAliveSection({required this.child});
  final Widget child;

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
