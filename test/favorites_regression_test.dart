import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

import 'support/backend_http.dart';

const _a = {'id': '1', 'type': 'MOVIE', 'title': 'A', 'ondeAssistir': '{}'};
const _b = {'id': '2', 'type': 'TV', 'title': 'B', 'ondeAssistir': '{}'};

class _Backend extends BackendHttp {
  bool failRead = false;
  bool failDelete = false;
  bool failAfterDelete = false;

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path == '/api/auth/login') {
      final payload = base64Url.encode(
        utf8.encode(
          jsonEncode({
            'exp':
                DateTime.now()
                    .add(const Duration(days: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        ),
      );
      return {
        'token': 'e30.$payload.test',
        'email': 'a@test.com',
        'nome': 'A',
        'fotoUrl': null,
      };
    }
    if ((failRead && method == 'GET' && uri.path == '/api/favoritos') ||
        (failDelete && method == 'DELETE')) {
      requests.add('$method ${uri.path.replaceFirst('/api', '')}');
      return {};
    }
    return super.respond(method, uri, body);
  }

  @override
  int responseStatus(String method, Uri uri) =>
      (failRead && method == 'GET' && uri.path == '/api/favoritos') ||
          ((failDelete || failAfterDelete) && method == 'DELETE')
      ? 503
      : 200;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Backend backend;
  late ApiService api;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previous = HttpOverrides.current;
    backend = _Backend();
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    api = ApiService();
    await api.logout();
    ApiService.token = 'account-a';
    backend.favorites.addAll([
      {'filmeSerieId': 1, 'tipoConteudo': 'MOVIE'},
      {'filmeSerieId': 2, 'tipoConteudo': 'TV'},
    ]);
  });
  tearDown(() async => api.logout());

  test(
    'concurrent removals across service instances keep the latest list',
    () async {
      await api.loadFavorites();
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.method == 'DELETE') {
              started.complete();
              await release.future;
            }
            handler.next(options);
          },
        ),
      );
      final first = api.toggleSaved(_a);
      await started.future;
      final second = ApiService().toggleSaved(_b);
      final refresh = ApiService().loadFavorites();
      expect(backend.requests.where((r) => r.startsWith('DELETE')), isEmpty);
      release.complete();
      await Future.wait([first, second, refresh]);
      expect(backend.favorites, isEmpty);
      expect(ApiService.savedContents, isEmpty);
    },
  );

  test('failed removal preserves state and does not block a retry', () async {
    await api.loadFavorites();
    backend.failDelete = true;
    await expectLater(api.toggleSaved(_a), throwsA(isA<DioException>()));
    expect(api.isSaved(_a), isTrue);
    expect(api.isSaved(_b), isTrue);
    backend.failDelete = false;
    await api.toggleSaved(_a);
    expect(api.isSaved(_a), isFalse);
    expect(api.isSaved(_b), isTrue);
    expect(backend.favorites, hasLength(1));
  });

  test(
    'retry preserves removal intent after a committed request returns an error',
    () async {
      await api.loadFavorites();
      backend.failAfterDelete = true;
      await expectLater(api.setSaved(_a, false), throwsA(isA<DioException>()));
      expect(backend.favorites, hasLength(1));
      backend.failAfterDelete = false;
      await api.setSaved(_a, false);
      expect(api.isSaved(_a), isFalse);
      expect(api.isSaved(_b), isTrue);
      expect(backend.requests.where((r) => r == 'POST /favoritos'), isEmpty);
    },
  );

  test(
    'login and restoration load favorites without opening their tab',
    () async {
      await api.loginApi('a@test.com', 'password');
      expect(api.isSaved(_a), isTrue);
      expect(api.isSaved(_b), isTrue);
      ApiService.token = null;
      expect(await api.restoreSession(), isTrue);
      expect(api.isSaved(_a), isTrue);
      expect(api.isSaved(_b), isTrue);
    },
  );

  test('favorite read failure preserves login and can be retried', () async {
    backend.failRead = true;
    await api.loginApi('a@test.com', 'password');
    expect(ApiService.hasSession, isTrue);
    expect(ApiService.savedContents, isEmpty);
    backend.failRead = false;
    await api.ensureFavoritesLoaded();
    expect(api.isSaved(_a), isTrue);
  });

  test(
    'queued work from an old session cannot change the new account',
    () async {
      await api.loadFavorites();
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.method == 'DELETE') {
              started.complete();
              await release.future;
            }
            handler.next(options);
          },
        ),
      );
      final first = api.toggleSaved(_a);
      final firstError = expectLater(first, throwsStateError);
      await started.future;
      final secondError = expectLater(api.toggleSaved(_b), throwsStateError);
      ApiService.token = 'account-b';
      release.complete();
      await Future.wait([firstError, secondError]);
      expect(ApiService.savedContents, isEmpty);
      expect(
        backend.requests.where((r) => r == 'DELETE /favoritos/2'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'details read favorites before visiting Favorites and stay synchronized',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const DetailsPage(content: _a),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FavoritesPage), findsNothing);
      expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
      expect(find.byTooltip('Adicionar aos favoritos'), findsNothing);
      await tester.runAsync(() => ApiService().toggleSaved(_a));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Adicionar aos favoritos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed initial read retries without accidentally adding a saved title',
    (tester) async {
      backend.failRead = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const DetailsPage(content: _a),
        ),
      );
      await tester.pumpAndSettle();
      backend.failRead = false;
      await tester.tap(find.byTooltip('Adicionar aos favoritos'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
      expect(backend.requests.where((r) => r == 'POST /favoritos'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
