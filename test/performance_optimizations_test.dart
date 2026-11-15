import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_poster.dart';

import 'support/backend_http.dart';

class _PerformanceBackend extends BackendHttp {
  bool failGenres = false;

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/episodios/painel')) {
      requests.add('$method ${uri.path}');
      return {'temporadas': []};
    }
    if (failGenres && uri.path.endsWith('/conteudos/generos')) {
      throw StateError('Gêneros indisponíveis');
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('reutiliza avaliações recentes e invalida após alterações', () async {
    final backend = _PerformanceBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    final api = ApiService();
    await api.open('performance@teste.com', 'Teste');
    ApiService.token = 'test-token';

    await Future.wait([api.getMyReviews(), api.getMyReviews()]);
    expect(
      backend.requests.where((request) => request == 'GET /avaliacoes/minhas'),
      hasLength(1),
    );

    const content = {'id': '123', 'type': 'MOVIE', 'title': 'Teste'};
    await api.saveReview(content, 8, 'Bom');
    await api.getMyReviews();
    expect(
      backend.requests.where((request) => request == 'GET /avaliacoes/minhas'),
      hasLength(2),
    );
    await api.deleteReview(ApiService.reviews.single);
    await api.getMyReviews();
    expect(
      backend.requests.where((request) => request == 'GET /avaliacoes/minhas'),
      hasLength(3),
    );
  });

  test('reutiliza painel da mesma série', () async {
    final backend = _PerformanceBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    final api = ApiService();
    await Future.wait([api.getEpisodePanel(1396), api.getEpisodePanel(1396)]);
    expect(
      backend.requests.where(
        (request) => request == 'GET /api/series/1396/episodios/painel',
      ),
      hasLength(1),
    );
  });

  testWidgets('Em alta carrega mesmo quando gêneros falham', (tester) async {
    final backend = _PerformanceBackend()..failGenres = true;
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = null;
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Em alta'), findsOneWidget);
    expect(find.text('Mais bem avaliados'), findsOneWidget);
    expect(
      find.textContaining('Não foi possível carregar os gêneros'),
      findsOneWidget,
    );
  });

  testWidgets('pôster TMDB usa versão menor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 144,
          height: 216,
          child: ContentPoster(
            content: {
              'poster_path': 'https://image.tmdb.org/t/p/w500/poster.jpg',
            },
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect(resized.width, 342);
    expect(
      (resized.imageProvider as NetworkImage).url,
      contains('/w342/poster.jpg'),
    );
  });
}
