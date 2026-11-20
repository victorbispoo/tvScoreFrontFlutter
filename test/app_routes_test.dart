import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/recovery_browser_url.dart'
    if (dart.library.js_interop) 'package:tv_score_front_flutter/core/recovery_browser_url_web.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/review_form.dart';

import 'support/backend_http.dart';

class _DetailsBackend extends BackendHttp {
  bool offline = false;

  @override
  int responseStatus(String method, Uri uri) =>
      uri.path.endsWith('/404') ? 404 : super.responseStatus(method, uri);

  @override
  Object? respond(String method, Uri uri, String body) {
    if (offline && uri.path == '/api/filmes/123') {
      throw const SocketException('Offline');
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  test(
    'reset links isolate tokens from route names and clean path and hash URLs',
    () {
      final token = 'a' * 43;
      for (final path in ['/redefinir-senha', '/#/redefinir-senha']) {
        final url = Uri.parse('https://example.test$path?token=$token');
        final entry = AppRoutes.recoveryRouteFromUrl(url)!;
        expect(entry.name, AppRoutes.resetPassword);
        expect(entry.arguments, token);
        expect(AppRoutes.generate(entry)!.settings.arguments, isNull);
        expect(AppRoutes.recoveryUrlWithoutToken(url).toString(), path);
      }
      final repeated = Uri.parse(
        'https://example.test/redefinir-senha?token=a&token=b',
      );
      expect(AppRoutes.recoveryRouteFromUrl(repeated)?.arguments, isNull);
      final malformed = Uri.parse(
        'https://example.test/redefinir-senha?token=%FF',
      );
      expect(AppRoutes.recoveryRouteFromUrl(malformed)?.arguments, isNull);
    },
  );

  if (kIsWeb) {
    test(
      'browser removes token from the address without leaving the current page',
      () {
        final original = Uri.base;
        try {
          final reset = Uri(
            path: original.path,
            fragment: '/redefinir-senha?token=example',
          );
          replaceRecoveryBrowserUrl(reset);
          expect(
            AppRoutes.recoveryRouteFromUrl(Uri.base)?.arguments,
            'example',
          );
          replaceRecoveryBrowserUrl(
            AppRoutes.recoveryUrlWithoutToken(Uri.base),
          );
          expect(Uri.base.fragment, '/redefinir-senha');
          expect(Uri.base.query, isEmpty);
        } finally {
          replaceRecoveryBrowserUrl(original);
        }
      },
    );
  }
  test('central routes preserve settings', () {
    for (final name in [
      AppRoutes.login,
      AppRoutes.home,
      AppRoutes.register,
      AppRoutes.search,
      AppRoutes.myReviews,
    ]) {
      final settings = RouteSettings(name: name);
      expect(AppRoutes.generate(settings)!.settings, same(settings));
    }
    expect(AppRoutes.generate(const RouteSettings(name: '/unknown')), isNull);
  });

  if (kIsWeb) return; // The widget fixtures use HttpOverrides.

  late _DetailsBackend backend;
  setUp(() {
    backend = _DetailsBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    ApiService.token = null;
    addTearDown(() {
      ApiService.token = null;
      HttpOverrides.global = previous;
    });
  });

  for (final (segment, type, id, resource) in [
    ('movie', 'MOVIE', 123, 'filmes'),
    ('tv', 'TV', 456, 'series'),
  ]) {
    testWidgets(
      'catalog opens $type with a persistent route and preserves Hero',
      (tester) async {
        final content = {
          'id': '$id',
          'type': type,
          'title': 'Catálogo $type',
          'ondeAssistir': '{}',
          'backdrop_path': 'assets/local-poster.png',
        };
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generate,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 140,
                  child: ContentCard(content: content, heroTag: 'poster-$type'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(ContentCard));
        await tester.pumpAndSettle();
        final details = find.byType(DetailsPage);
        expect(
          ModalRoute.of(tester.element(details))!.settings.name,
          '/details/$segment/$id',
        );
        expect(tester.widget<DetailsPage>(details).content, same(content));
        expect(tester.widget<DetailsPage>(details).heroTag, 'poster-$type');
        expect(backend.requests, isNot(contains('GET /$resource/$id')));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(ContentCard), findsOneWidget);
      },
      variant: const TargetPlatformVariant({TargetPlatform.android}),
    );

    testWidgets('opens /details/$segment/$id without in-memory arguments', (
      tester,
    ) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.defaultRouteNameTestValue = '/details/$segment/$id';
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      await tester.pumpWidget(const TvScoreApp());
      await tester.pumpAndSettle();
      final details = tester.widget<DetailsPage>(find.byType(DetailsPage));
      expect(details.content['id'], '$id');
      expect(details.content['type'], type);
      expect(
        backend.requests.where((path) => path == 'GET /$resource/$id'),
        hasLength(1),
      );
      expect(find.byType(ReviewForm), findsNothing);
      expect(find.text('Entrar para avaliar'), findsOneWidget);
      expect(backend.requests, isNot(contains('GET /favoritos')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Link de detalhes inválido.'), findsNothing);
    });
  }

  for (final path in [
    '/details',
    '/details/movie',
    '/details/person/123',
    '/details/tv/0',
    '/details/movie/-123',
    '/details/movie/abc',
    '/details/movie/9007199254740992',
    '/details/tv/123/extra',
  ]) {
    testWidgets('$path shows a safe error with a catalog action', (
      tester,
    ) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.defaultRouteNameTestValue = path;
      addTearDown(dispatcher.clearDefaultRouteNameTestValue);
      await tester.pumpWidget(const TvScoreApp());
      await tester.pumpAndSettle();
      expect(find.text('Link de detalhes inválido.'), findsOneWidget);
      expect(find.byType(DetailsPage), findsNothing);
      await tester.tap(find.text('Voltar ao catálogo'));
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Link de detalhes inválido.'), findsNothing);
    });
  }

  testWidgets('missing content shows a 404 state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/details/movie/404',
        onGenerateInitialRoutes: AppRoutes.initialDetailsRoutes,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conteúdo não encontrado.'), findsOneWidget);
    expect(find.text('Voltar ao catálogo'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  testWidgets('direct link loads favorites and the signed-in review', (
    tester,
  ) async {
    ApiService.token = 'route-fixture';
    backend.favorites.add({'filmeSerieId': 123, 'tipoConteudo': 'MOVIE'});
    backend.reviews.add({
      'id': 1,
      'filmeSerieId': 123,
      'tipoConteudo': 'MOVIE',
      'nota': 8.5,
      'comentario': 'Minha avaliação',
      'nomeUsuario': 'Teste',
      'dataCriacao': '2026-11-08T12:00:00',
    });
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/details/movie/123',
        onGenerateInitialRoutes: AppRoutes.initialDetailsRoutes,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    final form = tester.widget<ReviewForm>(find.byType(ReviewForm));
    expect(form.isEditing, isTrue);
    expect(form.rating, 8.5);
    expect(form.commentController.text, 'Minha avaliação');
    expect(find.text('Entrar para avaliar'), findsNothing);
  });

  testWidgets('network failure retries the same details route', (tester) async {
    backend.offline = true;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/details/movie/123',
        onGenerateInitialRoutes: AppRoutes.initialDetailsRoutes,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar os detalhes.'), findsOneWidget);
    backend.offline = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    expect(
      backend.requests.where((path) => path == 'GET /filmes/123'),
      hasLength(1),
    );
  });
}
