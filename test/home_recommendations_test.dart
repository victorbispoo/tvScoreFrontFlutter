import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/content_poster.dart';
import 'package:tv_score_front_flutter/widgets/ranked_content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/top_rated_carousel.dart';
import 'package:tv_score_front_flutter/widgets/trending_carousel.dart';

import 'support/backend_http.dart';

class _HomeBackend extends BackendHttp {
  _HomeBackend({
    this.preferred = true,
    this.multipleGenres = false,
    this.movieStatus = 200,
    this.seriesStatus = 200,
    this.empty = false,
    this.invalidResponse = false,
    this.networkFailure = false,
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
  final bool multipleGenres;
  final int movieStatus;
  final int seriesStatus;
  final bool empty;
  final bool invalidResponse;
  bool networkFailure;

  int get recommendationReads =>
      requests.where((request) => request.contains('/recomendacoes/')).length;

  @override
  int responseStatus(String method, Uri uri) => switch (uri.path) {
    '/api/recomendacoes/filmes' => movieStatus,
    '/api/recomendacoes/series' => seriesStatus,
    _ => 200,
  };

  @override
  Object? respond(String method, Uri uri, String body) {
    if (multipleGenres && uri.path.endsWith('/conteudos/generos')) {
      return [
        {'codigo': 'drama', 'nome': 'Drama'},
        {'codigo': 'comedia', 'nome': 'Comédia'},
        {'codigo': 'terror', 'nome': 'Terror'},
      ];
    }
    if (uri.path.endsWith('/usuarios/eu/generos')) {
      return {
        'generos': [
          if (preferred) {'codigo': 'drama'},
          if (multipleGenres) {'codigo': 'comedia'},
        ],
      };
    }
    if (uri.path.contains('/recomendacoes/')) {
      requests.add('$method ${uri.path}');
      if (networkFailure) throw const SocketException('Falha simulada');
      if (invalidResponse) return {'recomendacoes': 'inválido'};
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
  Future<void> mount(
    WidgetTester tester,
    _HomeBackend backend, {
    bool dark = false,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
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
      MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: const Scaffold(body: HomePage()),
      ),
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
      expect(
        personalized.first['recommendation_reason'],
        'Pelo seu gosto por drama',
      );
      expect(find.text('Pelo seu gosto por drama'), findsNothing);
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

  testWidgets(
    'organiza gêneros ao redor do ranking e filtra Para você localmente',
    (tester) async {
      final backend = _HomeBackend(multipleGenres: true);
      await mount(tester, backend, dark: true);
      await tester.pumpAndSettle();
      double y(String heading) => tester.getTopLeft(find.text(heading)).dy;
      final headings = [
        'Para você',
        'Em alta',
        'Drama',
        'Mais bem avaliados',
        'Comédia',
        'Descubra algo',
      ];
      for (var i = 1; i < headings.length; i++) {
        expect(y(headings[i - 1]), lessThan(y(headings[i])));
      }
      final personalized = find.byWidgetPredicate(
        (widget) =>
            widget is ContentCarousel && widget.heroSection == 'personalized',
      );
      final poster = find
          .descendant(of: personalized, matching: find.byType(ContentPoster))
          .first;
      expect(
        tester.widget<Text>(find.text('Para você')).style!.fontSize,
        closeTo(23 * 1.1, .01),
      );
      final cardTitle = find.descendant(
        of: personalized,
        matching: find.text('MOVIE 2'),
      );
      expect(
        tester.widget<Text>(cardTitle).style!.fontSize,
        closeTo(14 * 1.1, .01),
      );
      expect(
        find.descendant(of: personalized, matching: find.textContaining('•')),
        findsNothing,
      );
      expect(tester.getSize(poster).width, closeTo(158 * 1.1, .1));
      expect(
        tester.getSize(poster).height / tester.getSize(poster).width,
        closeTo(1.5, .01),
      );
      for (final (filter, expected) in [
        ('Filmes', ['MOVIE 2', 'MOVIE 3']),
        ('Séries', ['TV 2']),
        ('Todos', ['MOVIE 2', 'TV 2', 'MOVIE 3']),
      ]) {
        await tester.tap(
          find.descendant(of: personalized, matching: find.text(filter)),
        );
        await tester.pumpAndSettle();
        expect(titles(section(tester, 'personalized')), expected);
      }
      expect(backend.recommendationReads, 2);
    },
  );

  testWidgets('mantém filmes quando séries falham', (tester) async {
    await mount(tester, _HomeBackend(seriesStatus: 503));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(titles(section(tester, 'personalized')), ['MOVIE 2', 'MOVIE 3']);
  });

  testWidgets('mantém séries quando filmes falham', (tester) async {
    await mount(tester, _HomeBackend(movieStatus: 504));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(titles(section(tester, 'personalized')), ['TV 2']);
  });

  testWidgets('preserva scroll e reaproveita recomendações ao voltar', (
    tester,
  ) async {
    final backend = _HomeBackend();
    await mount(tester, backend);
    tester.view.physicalSize = const Size(390, 750);
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator, skipOffstage: false),
    );
    final horizontal = find.descendant(
      of: find.byWidgetPredicate(
        (widget) =>
            widget is ContentCarousel && widget.heroSection == 'personalized',
      ),
      matching: find.byType(Scrollable),
    );
    final horizontalPosition = tester
        .state<ScrollableState>(horizontal)
        .position;
    final verticalPosition = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    await tester.drag(horizontal, const Offset(-130, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(RefreshIndicator), const Offset(0, -230));
    await tester.pumpAndSettle();
    final horizontalOffset = horizontalPosition.pixels;
    final verticalOffset = verticalPosition.pixels;
    expect(horizontalOffset, greaterThan(0));
    expect(verticalOffset, greaterThan(0));

    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Outra tela')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();
    expect(horizontalPosition.pixels, horizontalOffset);
    expect(verticalPosition.pixels, verticalOffset);
    expect(backend.recommendationReads, 2);
  });

  testWidgets('descarta filme recebido antes de expirar a sessão', (
    tester,
  ) async {
    final backend = _HomeBackend(seriesStatus: 401)
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.add('/recomendacoes/series');
    await mount(tester, backend);
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.recommendationReads, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(ApiService.token, isNull);
    expect(titles(section(tester, 'personalized')).first, 'MOVIE 1');
    expect(find.byType(TrendingCarousel), findsOneWidget);
    expect(find.byType(RankedContentCarousel), findsOneWidget);
  });

  for (final (label, backend) in [
    ('offline', _HomeBackend(movieStatus: 503, seriesStatus: 503)),
    ('timeout', _HomeBackend(movieStatus: 504, seriesStatus: 504)),
    ('inválida', _HomeBackend(invalidResponse: true)),
    ('falha de rede', _HomeBackend(networkFailure: true)),
  ]) {
    testWidgets('Home segue utilizável com recomendação $label', (
      tester,
    ) async {
      await mount(tester, backend);
      await tester.pumpAndSettle();
      expect(titles(section(tester, 'personalized')).first, 'MOVIE 1');
      expect(find.byType(TrendingCarousel), findsOneWidget);
      expect(find.byType(RankedContentCarousel), findsOneWidget);
      if (backend.networkFailure) {
        backend.networkFailure = false;
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(titles(section(tester, 'personalized')).first, 'MOVIE 2');
        expect(backend.recommendationReads, 4);
      } else {
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(titles(section(tester, 'personalized')).first, 'MOVIE 1');
      }
    });
  }

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
