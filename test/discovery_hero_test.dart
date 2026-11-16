import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/poster_hero_tag.dart';
import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackendHttp backend;
  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  setUp(() async {
    final previous = HttpOverrides.current;
    backend = BackendHttp();
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await SharedPreferencesAsync().clear();
    await ApiService().open('teste@email.com', 'Teste');
  });

  test('tags incluem origem, obra e ocorrência', () {
    const movie = {'type': 'MOVIE', 'id': '1'};
    expect(
      posterHeroTag('search', movie),
      isNot(posterHeroTag('favorites', movie)),
    );
    expect(
      posterHeroTag('search', movie),
      isNot(posterHeroTag('search', movie, occurrence: 1)),
    );
  });

  testWidgets('Pesquisa mantém resultado e tag após abrir e voltar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: SearchPage()),
    );
    await tester.enterText(find.byType(TextField), 'avatar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final card = find.byType(ContentCard).first;
    final tag = tester.widget<ContentCard>(card).heroTag;
    expect(tag, isNotNull);
    final searchRequests = backend.requests
        .where((r) => r == 'GET /filmes/pesquisar')
        .length;
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(tester.widget<DetailsPage>(find.byType(DetailsPage)).heroTag, tag);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ContentCard>(find.byType(ContentCard).first).heroTag,
      tag,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'avatar',
    );
    expect(
      backend.requests.where((r) => r == 'GET /filmes/pesquisar'),
      hasLength(searchRequests),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favoritos remove obra nos detalhes sem restaurar card', (
    tester,
  ) async {
    final content = backend.catalog.first;
    await tester.runAsync(() => ApiService().toggleSaved(content));
    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: FavoritesPage()),
    );
    await tester.pumpAndSettle();
    final tag = tester.widget<ContentCard>(find.byType(ContentCard)).heroTag;
    expect(tag, posterHeroTag('favorites', content));
    await tester.tap(find.byType(ContentCard));
    await tester.pumpAndSettle();
    expect(tester.widget<DetailsPage>(find.byType(DetailsPage)).heroTag, tag);
    await tester.tap(find.byTooltip('Remover dos favoritos').last);
    await tester.pumpAndSettle();
    expect(find.byType(ContentCard, skipOffstage: false), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ContentCard), findsNothing);
    expect(ApiService.savedContents, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
