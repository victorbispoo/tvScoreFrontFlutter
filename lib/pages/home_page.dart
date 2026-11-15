import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';

import '../core/app_theme.dart';
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
  late Future<List<Map<String, String>>> _trending;
  late Future<List<Map<String, String>>> _topRated;
  int _minimumRating = 7;

  @override
  void initState() {
    super.initState();
    _sections = _loadSections();
    _trending = ApiService().getHighlights();
    _topRated = ApiService().getTopRatedMovies(_minimumRating);
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<HomeSection>> _loadSections() async {
    final api = ApiService();

    final (available, preferred) = await (
      api.getAvailableGenres(),
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
      for (var index = 0; forYou.length < 12; index++) {
        var added = false;
        for (final list in lists) {
          if (index < list.length && forYou.length < 12) {
            forYou.add(list[index]);
            added = true;
          }
        }
        if (!added) break;
      }

      sections.add((
        type: HomeSectionType.personalized,
        title: 'Para você',
        icon: HugeIconsSolid.sparkles,
        contents: forYou,
      ));
    }

    for (final genre in preferredGenres) {
      sections.add((
        type: HomeSectionType.genre,
        title: genre['nome'] as String,
        icon: genreIcon(genre['codigo'] as String),
        contents: contentsByCode[genre['codigo']] ?? [],
      ));
    }

    if (discoverGenre != null) {
      sections.add((
        type: HomeSectionType.discover,
        title: 'Descubra algo',
        icon: HugeIconsSolid.compass01,
        contents: contentsByCode[discoverGenre['codigo']] ?? [],
      ));
    }

    return sections;
  }

  Future<void> _refresh() async {
    final sections = _loadSections();
    final trending = ApiService().getHighlights();
    final topRated = ApiService().getTopRatedMovies(_minimumRating);
    setState(() {
      _sections = sections;
      _trending = trending;
      _topRated = topRated;
    });
    try {
      await (sections, trending, topRated).wait;
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
    required bool personalized,
  }) => FutureBuilder<List<HomeSection>>(
    future: _sections,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return personalized
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton(
                  onPressed: () => setState(() => _sections = _loadSections()),
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
      return Column(
        children: [
          for (final section in snapshot.data!)
            if ((section.type == HomeSectionType.personalized) == personalized)
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: Icon(
                  section.icon,
                  size: personalized ? 18 : 16,
                  color: AppTheme.primary,
                ),
                title: section.title,
                contents: section.contents,
                featured: personalized,
              ),
        ],
      );
    },
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
                  SvgPicture.asset('lib/assets/logoTvScore.svg', height: 44),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Pesquisar',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchPage()),
                      );
                    },
                    icon: Icon(
                      HugeIconsSolid.search01,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _genreSections(personalized: true),
          FutureBuilder<List<Map<String, String>>>(
            future: _trending,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () =>
                      setState(() => _trending = ApiService().getHighlights()),
                  child: const Text(
                    'Não foi possível carregar Em alta. Tentar novamente',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const SkeletonCarousel(showFilters: true);
              }
              return TrendingCarousel(
                contents: snapshot.data!,
                onChanged: () => setState(() {}),
              );
            },
          ),
          TopRatedCarousel(
            minimumRating: _minimumRating,
            onMinimumSelected: (minimum) => setState(() {
              _minimumRating = minimum;
              _topRated = ApiService().getTopRatedMovies(minimum);
            }),
            onRetry: () => setState(() {
              _topRated = ApiService().getTopRatedMovies(_minimumRating);
            }),
            contents: _topRated,
            onChanged: () => setState(() {}),
          ),
          _genreSections(personalized: false),
        ],
      ),
    );
  }
}
