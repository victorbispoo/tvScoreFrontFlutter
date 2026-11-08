import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';

import '../core/app_theme.dart';
import '../services/api_services.dart';
import '../widgets/content_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, String>>> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = ApiService().getHighlights();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _refresh() async {
    final future = ApiService().getHighlights();
    setState(() => _catalog = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: _refresh,
              child: const Text('Tentar novamente'),
            ),
          );
        }
        final contents = snapshot.data ?? [];
        final best = contents.toList()
          ..sort(
            (a, b) =>
                double.parse(b['score']!).compareTo(double.parse(a['score']!)),
          );
        final recent = contents.toList()
          ..sort((a, b) => b['year']!.compareTo(a['year']!));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'lib/assets/logoSemTexto.svg',
                          width: 130,
                          height: 70,
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
                          icon: Icon(HugeIconsSolid.search01),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(HugeIconsSolid.fire, color: AppTheme.primary),
                title: 'Destaques',
                subtitle: 'Histórias que merecem sua atenção',
                contents: contents.take(6).toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(HugeIconsSolid.star, color: AppTheme.primary),
                title: 'Mais bem avaliados',
                subtitle: 'As maiores notas do catálogo',
                contents: best.take(8).toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(
                  HugeIconsSolid.clock01,
                  color: AppTheme.primary,
                ),
                title: 'Mais recentes no catálogo',
                contents: recent.take(8).toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(
                  HugeIconsSolid.sword01,
                  color: AppTheme.primary,
                ),
                title: 'Ação e aventura',
                contents: contents
                    .where((content) => content['genre']!.contains('Ação'))
                    .toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(
                  HugeIconsSolid.rocket01,
                  color: AppTheme.primary,
                ),
                title: 'Ficção científica',
                contents: contents
                    .where((content) => content['genre']!.contains('Ficção'))
                    .toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(
                  HugeIconsSolid.film01,
                  color: AppTheme.primary,
                ),
                title: 'Drama e grandes clássicos',
                contents: contents
                    .where((content) => content['genre']!.contains('Drama'))
                    .toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(HugeIconsSolid.tv01, color: AppTheme.primary),
                title: 'Séries para maratonar',
                contents: contents
                    .where((content) => content['type'] == 'TV')
                    .toList(),
              ),
              ContentCarousel(
                onChanged: () => setState(() {}),
                icon: const Icon(
                  HugeIconsSolid.bookmark01,
                  color: AppTheme.primary,
                ),
                title: 'Na sua lista',
                contents: ApiService.savedContents,
              ),
            ],
          ),
        );
      },
    );
  }
}
