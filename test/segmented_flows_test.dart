import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/top_rated_carousel.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_segmented_control.dart';

import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BackendHttp backend;
  setUp(() async {
    backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().open('segmentos@teste.com', 'Teste');
    ApiService.token = 'test-token';
  });

  test(
    'Top Rated combina tipos, ordena e mantém uma consulta por endpoint',
    () async {
      final contents = await ApiService().getTopRatedContents('ALL');
      expect(contents.map((item) => item['type']).toSet(), {'MOVIE', 'TV'});
      final ratings = contents
          .map((item) => double.parse(item['score']!))
          .toList();
      expect(
        ratings,
        orderedEquals([...ratings]..sort((a, b) => b.compareTo(a))),
      );
      expect(backend.requests, [
        'GET /filmes/por-nota',
        'GET /series/por-nota',
      ]);
      await expectLater(
        ApiService().getTopRatedContents('invalid'),
        throwsArgumentError,
      );
      expect(backend.requests, hasLength(2));
    },
  );

  testWidgets('Top Rated faz a consulta somente ao confirmar a seleção', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );
    await tester.pumpAndSettle();
    final control = find.descendant(
      of: find.byType(TopRatedCarousel),
      matching: find.byType(TvScoreSegmentedControl<String>),
    );
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    final requests = [...backend.requests];
    final origin = tester.getTopLeft(control) + const Offset(40, 24);
    final gesture = await tester.startGesture(origin);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(Offset(tester.getSize(control).width * 2 / 3, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(backend.requests, requests);
    expect(
      tester
          .widget<TopRatedCarousel>(find.byType(TopRatedCarousel))
          .selectedType,
      'ALL',
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TopRatedCarousel>(find.byType(TopRatedCarousel))
          .selectedType,
      'TV',
    );
    expect(backend.requests.length, requests.length + 1);
    expect(backend.requests.last, 'GET /series/por-nota');
    await tester.tap(
      find.descendant(of: control, matching: find.text('Séries')),
    );
    await tester.pumpAndSettle();
    expect(backend.requests.length, requests.length + 1);
  });

  testWidgets('Minhas avaliações só reordena ao soltar e não repete HTTP', (
    tester,
  ) async {
    backend.reviews.addAll([
      {
        'id': 1,
        'filmeSerieId': 1000,
        'tipoConteudo': 'MOVIE',
        'nota': 9.0,
        'comentario': 'Alta',
        'dataCriacao': '2026-11-01T12:00:00',
      },
      {
        'id': 2,
        'filmeSerieId': 1001,
        'tipoConteudo': 'TV',
        'nota': 5.0,
        'comentario': 'Recente',
        'dataCriacao': '2026-11-15T12:00:00',
      },
    ]);
    await tester.pumpWidget(const MaterialApp(home: MyReviewsPage()));
    await tester.pumpAndSettle();
    final requests = [...backend.requests];
    double recentY() => tester.getTopLeft(find.text('Recente')).dy;
    double highY() => tester.getTopLeft(find.text('Alta')).dy;
    expect(recentY(), lessThan(highY()));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Mais recentes')),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(112, 0));
    await tester.pump();
    expect(recentY(), lessThan(highY()));
    expect(backend.requests, requests);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(highY(), lessThan(recentY()));
    expect(backend.requests, requests);
    expect(tester.takeException(), isNull);
  });
}
