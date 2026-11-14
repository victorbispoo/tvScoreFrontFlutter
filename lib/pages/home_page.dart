import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';

import '../core/app_theme.dart';
import '../services/api_services.dart';
import '../widgets/content_carousel.dart';
import '../widgets/genre_preferences.dart';
import '../widgets/top_rated_carousel.dart';
import '../widgets/trending_carousel.dart';

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
  late Future<List<Map<String, String>>> _topRated;
  int _minimumRating = 7;

  @override
  void initState() {
    super.initState();
    _sections = _loadSections();
    _topRated = ApiService().getTopRatedMovies(_minimumRating);
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<HomeSection>> _loadSections() async {
    final api = ApiService();

    final trending = await api.getHighlights();
    final available = await api.getAvailableGenres();

    final preferred = ApiService.token == null
        ? <Map<String, dynamic>>[]
        : await api.getPreferredGenres();

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

    sections.add((
      type: HomeSectionType.trending,
      title: 'Em alta',
      icon: HugeIconsSolid.fire,
      contents: trending,
    ));

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
    try {
      final sections = await _loadSections();
      if (mounted) {
        setState(() {
          _sections = Future.value(sections);
          _topRated = ApiService().getTopRatedMovies(_minimumRating);
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao atualizar Home: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível atualizar a Home.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<HomeSection>>(
      future: _sections,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListView(
            padding: const EdgeInsets.only(top: 90),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Carregando títulos...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 264,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => Container(
                    width: 176,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: _refresh,
              child: const Text('Tentar novamente'),
            ),
          );
        }

        final sections = snapshot.data ?? [];

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
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Pesquisar',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchPage(),
                            ),
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
              for (final section in sections) ...[
                if (section.type == HomeSectionType.trending) ...[
                  TrendingCarousel(
                    contents: section.contents,
                    onChanged: () => setState(() {}),
                  ),
                  TopRatedCarousel(
                    minimumRating: _minimumRating,
                    onMinimumSelected: (minimum) => setState(() {
                      _minimumRating = minimum;
                      _topRated = ApiService().getTopRatedMovies(minimum);
                    }),
                    onRetry: () => setState(() {
                      _topRated = ApiService().getTopRatedMovies(
                        _minimumRating,
                      );
                    }),
                    contents: _topRated,
                    onChanged: () => setState(() {}),
                  ),
                ] else
                  ContentCarousel(
                    onChanged: () => setState(() {}),
                    icon: Icon(
                      section.icon,
                      size: section.type == HomeSectionType.personalized
                          ? 18
                          : 16,
                      color: AppTheme.primary,
                    ),
                    title: section.title,
                    contents: section.contents,
                    featured: section.type == HomeSectionType.personalized,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
