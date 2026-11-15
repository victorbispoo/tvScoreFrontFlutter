import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/models/search_filters.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';

import 'support/backend_http.dart';

void main() {
  test('combina tipo, gêneros, ano e nota TMDB', () {
    const filters = SearchFilters(
      type: 'TV',
      genres: {'Drama', 'Comédia'},
      year: 2024,
      minimumRating: 8,
    );
    const content = {
      'type': 'TV',
      'genre': 'Aventura • Drama',
      'year': '2024',
      'score': '8.3',
    };
    expect(filters.matches(content), isTrue);
    expect(filters.matches({...content, 'type': 'MOVIE'}), isFalse);
    expect(filters.matches({...content, 'genre': 'Aventura'}), isFalse);
    expect(filters.matches({...content, 'year': '2023'}), isFalse);
    expect(filters.matches({...content, 'score': '7.9'}), isFalse);
  });

  testWidgets('filtra páginas, mantém o termo e limpa filtros', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final backend = BackendHttp()..searchPageSize = 1;
    backend.catalog
      ..clear()
      ..addAll([
        {
          'id': '1',
          'type': 'MOVIE',
          'title': 'Teste filme',
          'year': '2024',
          'score': '6.0',
          'genre': 'Drama',
        },
        {
          'id': '2',
          'type': 'TV',
          'title': 'Teste série',
          'year': '2024',
          'score': '8.5',
          'genre': 'Drama',
        },
      ]);
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const SearchPage()),
    );
    expect(find.text('Digite o nome de um filme ou série.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Teste');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Teste filme'), findsOneWidget);

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Séries'));
    await tester.tap(find.text('Drama'));
    await tester.ensureVisible(find.text('8+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8+'));
    await tester.enterText(find.widgetWithText(TextField, 'Ex.: 2024'), '2024');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum título corresponde aos filtros nesta página.'),
      findsOneWidget,
    );
    expect(find.text('Resultados para “Teste”'), findsOneWidget);
    await tester.tap(find.text('Buscar mais páginas'));
    await tester.pumpAndSettle();
    expect(find.text('Teste série'), findsOneWidget);
    expect(find.text('Teste filme'), findsNothing);

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.tap(find.text('Aplicar filtros'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Teste filme'), findsOneWidget);
    expect(find.text('Resultados para “Teste”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fechar filtros preserva busca e erro permite tentar novamente', (
    tester,
  ) async {
    final backend = BackendHttp()..failSearch = true;
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const SearchPage()),
    );
    await tester.enterText(find.byType(TextField).first, 'avatar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível pesquisar. Tente novamente.'),
      findsOneWidget,
    );

    final requests = backend.requests.length;
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados para “avatar”'), findsOneWidget);
    expect(
      backend.requests.where((request) => request == 'GET /filmes/pesquisar'),
      hasLength(requests),
    );

    backend.failSearch = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Avatar: O Caminho da Água'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet cabe em tela pequena com teclado aberto', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const SearchPage()),
    );
    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Aplicar filtros'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
