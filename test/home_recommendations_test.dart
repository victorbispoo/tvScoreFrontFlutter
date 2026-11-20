import 'dart:io';

import 'package:dio/dio.dart';
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
    this.paginated = false,
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
  final bool paginated;

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
    if (uri.path.endsWith('/conteudos/por-genero')) {
      final code = uri.queryParameters['genero'];
      final page = uri.queryParameters['pagina'];
      requests.add('GET gênero $code página $page');
      Map<String, dynamic> extra(int id) => details({
        'id': '$id',
        'type': 'MOVIE',
        'title': 'Gênero $id',
        'year': '2024',
        'score': '8.0',
      });
      return {
        if (paginated) 'total_pages': 3,
        'results': [
          if (page == '2')
            extra(105)
          else if (code == 'drama') ...[
            for (final i in [0, 1, 2, 4]) details(catalog[i]),
            if (!paginated) extra(101),
          ] else if (code == 'comedia') ...[
            details(catalog[3]),
            extra(101),
            extra(102),
          ] else ...[
            details(catalog[5]),
            extra(102),
            extra(103),
          ],
        ],
      };
    }
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

class _MissingYearBackend extends _HomeBackend {
  bool offline = false;

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.contains('/recomendacoes/')) {
      requests.add('$method ${uri.path}');
      return {
        'recomendacoes': [
          {'id': 97, 'titulo': 'Recommended'},
          if (uri.path.endsWith('/filmes')) ...[
            {'id': 97, 'titulo': 'Duplicate'},
            {'id': 98, 'titulo': 'Undated'},
          ],
        ],
      };
    }
    if (RegExp(r'/(filmes|series)/(97|98)$').hasMatch(uri.path)) {
      requests.add('$method ${uri.path}');
      if (offline) throw const SocketException('Offline');
      return {
        'id': int.parse(uri.path.split('/').last),
        if (uri.path.endsWith('/97'))
          if (uri.path.contains('/filmes/'))
            'release_date': '2014-11-06'
          else
            'first_air_date': '2008-01-20',
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

  for (final offline in [false, true]) {
    testWidgets(
      'hydrates missing years without duplicate reads, offline=$offline',
      (tester) async {
        final backend = _MissingYearBackend()..offline = offline;
        await mount(tester, backend);
        await tester.pumpAndSettle();
        final contents = section(tester, 'personalized');
        expect(contents.map((item) => (item['id'], item['type'])), [
          ('97', 'MOVIE'),
          ('97', 'TV'),
          ('98', 'MOVIE'),
        ]);
        expect(
          contents.map((item) => item['year']),
          offline ? ['', '', ''] : ['2014', '2008', ''],
        );
        for (final path in ['/filmes/97', '/series/97', '/filmes/98']) {
          expect(
            backend.requests.where((item) => item.endsWith(path)),
            hasLength(1),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

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
      expect(personalized.map((content) => content['year']), [
        '2026',
        '2026',
        '2026',
      ]);
      expect(
        backend.requests.where(
          (item) => RegExp(r'/(filmes|series)/\d+$').hasMatch(item),
        ),
        isEmpty,
      );
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
        ['MOVIE 1', 'MOVIE 4', 'TV 3'],
      );
      expect(
        titles(
          tester
              .widget<RankedContentCarousel>(find.byType(RankedContentCarousel))
              .contents,
        ),
        ['MOVIE 4', 'MOVIE 2', 'TV 2', 'MOVIE 1', 'TV 3', 'MOVIE 3'],
      );
      expect(titles(section(tester, 'genre:drama')), ['Gênero 101']);
      expect(titles(section(tester, 'discover:comedia')), ['Gênero 102']);

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
      expect(titles(section(tester, 'trending')), ['TV 3']);
      expect(titles(section(tester, 'genre:drama')), ['MOVIE 1', 'Gênero 101']);
      backend.delayedPaths.clear();
      final refreshing = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refreshing;
      expect(backend.recommendationReads, 4);
      expect(titles(section(tester, 'trending')), ['TV 3']);
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
        findsWidgets,
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
        if (filter == 'Filmes') {
          expect(titles(section(tester, 'trending')), contains('TV 2'));
        }
      }
      expect(titles(section(tester, 'genre:drama')), ['Gênero 101']);
      expect(titles(section(tester, 'genre:comedia')), ['Gênero 102']);
      expect(titles(section(tester, 'discover:terror')), ['Gênero 103']);
      expect(backend.recommendationReads, 2);
    },
  );

  testWidgets('repõe um gênero vazio com uma única página adicional', (
    tester,
  ) async {
    final backend = _HomeBackend(paginated: true);
    await mount(tester, backend);
    await tester.pumpAndSettle();
    expect(titles(section(tester, 'genre:drama')), ['Gênero 105']);
    expect(backend.requests.where((entry) => entry.endsWith('página 2')), [
      'GET gênero drama página 2',
    ]);
    expect(
      backend.requests.where((entry) => entry.endsWith('página 3')),
      isEmpty,
    );
  });

  testWidgets('mantém prioridades se o catálogo terminar depois da IA', (
    tester,
  ) async {
    final backend = _HomeBackend()
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.addAll(['/conteudos/por-genero', '/filmes/em-alta']);
    await mount(tester, backend);
    await tester.pump(const Duration(milliseconds: 100));
    expect(titles(section(tester, 'personalized')), [
      'MOVIE 2',
      'TV 2',
      'MOVIE 3',
    ]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(titles(section(tester, 'trending')), ['MOVIE 1', 'MOVIE 4', 'TV 3']);
    expect(titles(section(tester, 'genre:drama')), ['Gênero 101']);
    expect(titles(section(tester, 'discover:comedia')), ['Gênero 102']);
    expect(backend.recommendationReads, 2);
  });

  testWidgets('recompõe a Home quando um favorito invalida as recomendações', (
    tester,
  ) async {
    final backend = _HomeBackend();
    await mount(tester, backend);
    await tester.pumpAndSettle();
    expect(backend.recommendationReads, 2);
    final api = ApiService();
    api.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) =>
            handler.resolve(Response(requestOptions: options, statusCode: 201)),
      ),
    );
    final save = api.addFavourite({'type': 'MOVIE', 'id': '2'});
    await tester.pump(const Duration(milliseconds: 100));
    await save;
    await tester.pumpAndSettle();
    expect(backend.recommendationReads, 4);
    expect(titles(section(tester, 'trending')), ['MOVIE 1', 'MOVIE 4', 'TV 3']);
  });

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
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ContentCarousel && widget.heroSection == 'personalized',
      ),
      findsNothing,
    );
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
      expect(find.text('Drama'), findsNothing);
    });
  }
}
