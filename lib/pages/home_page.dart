import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';

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
import '../widgets/tv_score_snackbar.dart';

enum HomeSectionType { personalized, trending, genre, discover }

typedef HomeSection = ({
  HomeSectionType type,
  String heroSection,
  String title,
  IconData icon,
  List<Map<String, String>> contents,
});

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
  List<Map<String, String>> _forYouRecommendations = const [];
  Set<(String?, String?)> _recommended = const {};
  String _topRatedType = 'ALL';

  @override
  void initState() {
    super.initState();
    _availableGenres = ApiService().getAvailableGenres();
    _sections = _loadSections();
    _trending = ApiService().getHighlights();
    _topRated = ApiService().getTopRatedContents(_topRatedType);
    _loadRecommendations();
    ApiService.contentPreferencesRevision.addListener(_reloadPreferences);
  }

  void _reloadPreferences() {
    setState(() {
      _sections = _loadSections();
    });
    _loadRecommendations();
  }

  Future<void> _loadRecommendations({bool refresh = false}) {
    final token = ApiService.token;
    if (token == null) {
      _recommendationLoad = null;
      _recommended = const {};
      _forYouRecommendations = const [];
      return Future.value();
    }
    final api = ApiService();
    Future<List<Recommendation>> read(Future<Recommendations> request) async {
      try {
        return (await request).items;
      } on RecommendationException {
        return const [];
      }
    }

    late final Future<void> load;
    load =
        Future.wait([
          read(api.getMovieRecommendations(refresh: refresh)),
          read(api.getSeriesRecommendations(refresh: refresh)),
        ]).then((results) {
          if (!mounted || !identical(_recommendationLoad, load)) return;
          if (ApiService.token != token) {
            setState(() {
              _recommended = const {};
              _forYouRecommendations = const [];
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
    ApiService.contentPreferencesRevision.removeListener(_reloadPreferences);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<HomeSection>> _loadSections() async {
    final api = ApiService();

    final (available, preferred) = await (
      _availableGenres,
      ApiService.token == null
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

    final results = await Future.wait(codesToLoad.map(api.getContentsByGenre));

    final contentsByCode = Map<String, List<Map<String, String>>>.fromIterables(
      codesToLoad,
      results,
    );

    final sections = <HomeSection>[];

    if (preferredGenres.isNotEmpty) {
      final lists = preferredGenres
          .map(
            (genre) =>
                contentsByCode[genre['codigo']] ?? <Map<String, String>>[],
          )
          .toList();
      final forYou = <Map<String, String>>[];
      final seen = <(String?, String?)>{};
      for (var index = 0; forYou.length < 12; index++) {
        var added = false;
        for (final list in lists) {
          if (index < list.length && forYou.length < 12) {
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
      ));
    }

    for (final genre in preferredGenres) {
      sections.add((
        type: HomeSectionType.genre,
        heroSection: 'genre:${genre['codigo']}',
        title: genre['nome'] as String,
        icon: genreIcon(genre['codigo'] as String),
        contents: contentsByCode[genre['codigo']] ?? [],
      ));
    }

    if (discoverGenre != null) {
      sections.add((
        type: HomeSectionType.discover,
        heroSection: 'discover:${discoverGenre['codigo']}',
        title: 'Descubra algo',
        icon: HugeIconsSolid.compass01,
        contents: contentsByCode[discoverGenre['codigo']] ?? [],
      ));
    }

    return sections;
  }

  Future<void> _refresh() async {
    _availableGenres = ApiService().getAvailableGenres();
    final sections = _loadSections();
    final trending = ApiService().getHighlights();
    final topRated = ApiService().getTopRatedContents(_topRatedType);
    setState(() {
      _sections = sections;
      _trending = trending;
      _topRated = topRated;
    });
    final recommendations = _loadRecommendations(refresh: true);
    try {
      await (sections, trending, topRated, recommendations).wait;
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

  Widget _genreSections({required bool personalized}) => _KeepAliveSection(
    child: FutureBuilder<List<HomeSection>>(
      future: _sections,
      builder: (context, snapshot) {
        if (personalized && _forYouRecommendations.isNotEmpty) {
          return _personalizedCarousel(_forYouRecommendations);
        }
        if (snapshot.hasError) {
          return personalized
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: () => setState(() {
                      _availableGenres = ApiService().getAvailableGenres();
                      _sections = _loadSections();
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
              ? const SkeletonCarousel(featured: true)
              : const SizedBox.shrink();
        }
        if (personalized) {
          final fallback = snapshot.data!
              .where((section) => section.type == HomeSectionType.personalized)
              .firstOrNull
              ?.contents;
          if (fallback != null && fallback.isNotEmpty) {
            return _personalizedCarousel(fallback);
          }
          return FutureBuilder(
            future: _trending,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SizedBox.shrink();
              if (!snapshot.hasData) {
                return const SkeletonCarousel(featured: true);
              }
              final seen = <(String?, String?)>{};
              return _personalizedCarousel(
                snapshot.data!
                    .where((content) => seen.add(content.contentKey))
                    .take(12)
                    .toList(),
              );
            },
          );
        }
        return Column(
          children: [
            for (final section in snapshot.data!)
              if (section.type != HomeSectionType.personalized)
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
                  contents: section.type == HomeSectionType.genre
                      ? _prioritizeMatches(section.contents)
                      : section.contents,
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
        onChanged: () => setState(() {}),
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
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
          _genreSections(personalized: true),
          _KeepAliveSection(
            child: FutureBuilder<List<Map<String, String>>>(
              future: _trending,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: () => setState(
                      () => _trending = ApiService().getHighlights(),
                    ),
                    child: const Text(
                      'Não foi possível carregar Em alta. Tentar novamente',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SkeletonCarousel(showFilters: true);
                }
                return TrendingCarousel(
                  contents: _prioritizeTrending(snapshot.data!),
                  onChanged: () => setState(() {}),
                  heroSection: 'trending',
                );
              },
            ),
          ),
          _KeepAliveSection(
            child: TopRatedCarousel(
              heroSection: 'top-rated',
              selectedType: _topRatedType,
              onTypeSelected: (type) => setState(() {
                _topRatedType = type;
                _topRated = ApiService().getTopRatedContents(type);
              }),
              onRetry: () => setState(() {
                _topRated = ApiService().getTopRatedContents(_topRatedType);
              }),
              contents: _topRated,
              orderContents: _prioritizeRated,
              onChanged: () => setState(() {}),
            ),
          ),
          _genreSections(personalized: false),
        ],
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
