import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/ranked_content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/top_rated_carousel.dart';
import 'package:tv_score_front_flutter/widgets/trending_carousel.dart';

import 'support/backend_http.dart';

class _HomeBackend extends BackendHttp {
  _HomeBackend({
    this.preferred = true,
    this.failSeries = false,
    this.empty = false,
  }) {
    catalog
      ..clear()
      ..addAll([
        for (final (id, type, score) in const [
          ('1', 'MOVIE', '8.5'),
          ('2', 'MOVIE', '8.5'),
          ('3', 'MOVIE', '7.5'),
          ('4', 'MOVIE', '9.5'),
          ('2', 'TV', '8.5'),
          ('3', 'TV', '8.5'),
        ])
          {
            'id': id,
            'type': type,
            'title': '$type $id',
            'score': score,
            'year': '2026',
          },
      ]);
  }

  final bool preferred;
  final bool failSeries;
  final bool empty;

  int get recommendationReads =>
      requests.where((request) => request.contains('/recomendacoes/')).length;

  @override
  int responseStatus(String method, Uri uri) =>
      failSeries && uri.path.endsWith('/recomendacoes/series') ? 503 : 200;

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/usuarios/eu/generos')) {
      return {
        'generos': [
          if (preferred) {'codigo': 'drama'},
        ],
      };
    }
    if (uri.path.contains('/recomendacoes/')) {
      requests.add('$method ${uri.path}');
      return {
        'recomendacoes': [
          if (!empty && uri.path.endsWith('/filmes')) ...[
            {
              'id': 2,
              'titulo': 'MOVIE 2',
              'score_recomendacao': 0.3,
              'motivo_recomendacao': 'Pelo seu gosto por drama',
            },
            {'id': 2, 'titulo': 'Duplicado'},
            {'id': 3, 'titulo': 'MOVIE 3', 'score_recomendacao': 1},
          ],
          if (!empty && uri.path.endsWith('/series'))
            {'id': 2, 'titulo': 'TV 2', 'score_recomendacao': 99},
        ],
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  Future<void> mount(WidgetTester tester, _HomeBackend backend) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    ApiService.token = 'home-recommendations';
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1900);
    addTearDown(() {
      HttpOverrides.global = previous;
      ApiService.token = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );
  }

  List<Map<String, String>> section(WidgetTester tester, String heroSection) =>
      tester
          .widget<ContentCarousel>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is ContentCarousel &&
                  widget.heroSection == heroSection,
            ),
          )
          .contents;

  Iterable<String?> titles(List<Map<String, String>> contents) =>
      contents.map((content) => content['title']);

  testWidgets(
    'personaliza a Home sem refazer IA nos filtros e força no refresh',
    (tester) async {
      final backend = _HomeBackend()
        ..responseDelay = const Duration(seconds: 2)
        ..delayedPaths.addAll([
          '/recomendacoes/filmes',
          '/recomendacoes/series',
        ]);
      await mount(tester, backend);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Em alta'), findsOneWidget);
      expect(find.byType(RankedContentCarousel), findsOneWidget);
      expect(titles(section(tester, 'personalized')).first, 'MOVIE 1');

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final personalized = section(tester, 'personalized');
      expect(titles(personalized), ['MOVIE 2', 'TV 2', 'MOVIE 3']);
      expect(personalized.first['recommendation_score'], '0.3');
      expect(find.text('Pelo seu gosto por drama'), findsOneWidget);
      expect(
        titles(
          tester
              .widget<TrendingCarousel>(find.byType(TrendingCarousel))
              .contents,
        ),
        ['MOVIE 2', 'MOVIE 1', 'MOVIE 3', 'MOVIE 4', 'TV 2', 'TV 3'],
      );
      expect(
        titles(
          tester
              .widget<RankedContentCarousel>(find.byType(RankedContentCarousel))
              .contents,
        ),
        ['MOVIE 4', 'MOVIE 2', 'TV 2', 'MOVIE 1', 'TV 3', 'MOVIE 3'],
      );
      expect(titles(section(tester, 'genre:drama')), [
        'MOVIE 2',
        'MOVIE 3',
        'TV 2',
        'MOVIE 1',
        'MOVIE 4',
        'TV 3',
      ]);
      expect(titles(section(tester, 'discover:comedia')), [
        'MOVIE 1',
        'MOVIE 2',
        'MOVIE 3',
        'MOVIE 4',
        'TV 2',
        'TV 3',
      ]);

      for (final carousel in [TrendingCarousel, TopRatedCarousel]) {
        await tester.tap(
          find.descendant(
            of: find.byType(carousel),
            matching: find.text('Séries'),
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(backend.recommendationReads, 2);
      backend.delayedPaths.clear();
      final refreshing = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refreshing;
      expect(backend.recommendationReads, 4);
    },
  );

  testWidgets('mantém filmes quando séries falham', (tester) async {
    await mount(tester, _HomeBackend(failSeries: true));
    await tester.pumpAndSettle();
    expect(titles(section(tester, 'personalized')), ['MOVIE 2', 'MOVIE 3']);
  });

  for (final preferred in [true, false]) {
    testWidgets('usa fallback se a IA vier vazia, preferências: $preferred', (
      tester,
    ) async {
      await mount(tester, _HomeBackend(preferred: preferred, empty: true));
      await tester.pumpAndSettle();
      expect(titles(section(tester, 'personalized')).first, 'MOVIE 1');
      expect(find.text('Para você'), findsOneWidget);
      expect(find.text('Drama'), preferred ? findsWidgets : findsNothing);
    });
  }
}
