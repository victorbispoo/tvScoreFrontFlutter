import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';

import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiService api;

  setUp(() {
    final previous = HttpOverrides.current;
    HttpOverrides.global = BackendHttp();
    addTearDown(() => HttpOverrides.global = previous);
    api = ApiService();
    ApiService.token = 'test-token';
    ApiService.savedContents = [];
    ApiService.reviews = [];
    addTearDown(() {
      ApiService.token = null;
      ApiService.savedContents = [];
      ApiService.reviews = [];
    });
  });

  const movie = {'id': '123', 'type': 'MOVIE', 'title': 'Filme'};
  const series = {'id': '123', 'type': 'TV', 'title': 'Série'};

  test(
    'favoritar ou remover um filme não altera a série com o mesmo ID',
    () async {
      await api.toggleSaved(movie);
      await api.toggleSaved(series);
      expect(api.isSaved(movie), isTrue);
      expect(api.isSaved(series), isTrue);

      await api.toggleSaved(movie);
      expect(api.isSaved(movie), isFalse);
      expect(api.isSaved(series), isTrue);
    },
  );

  test(
    'editar a nota do filme preserva a avaliação da série com mesmo ID',
    () async {
      await api.saveReview(movie, 7.5, 'Filme');
      await api.saveReview(series, 9, 'Série');
      await api.saveReview(movie, 8, 'Editado');
      expect(ApiService.reviews, hasLength(2));
      expect(api.reviewFor(movie)?.rating, 8);
      expect(api.reviewFor(movie)?.comment, 'Editado');
      expect(api.reviewFor(series)?.rating, 9);
      expect(api.reviewFor(series)?.comment, 'Série');
    },
  );

  test('IDs não positivos são recusados antes de enviar favoritos', () async {
    await expectLater(
      api.addFavourite({'id': '0', 'type': 'MOVIE'}),
      throwsArgumentError,
    );
    await expectLater(
      api.removeFavourite({'id': '-1', 'type': 'TV'}),
      throwsArgumentError,
    );
  });

  testWidgets('card apresenta somente o gênero principal do contrato interno', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 290,
            child: ContentCard(
              content: {
                ...movie,
                'year': '2024',
                'genre': 'Animação • Ação e Aventura • Comédia',
                'genre_ids': '16 | 10759 | 35',
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2024 • Animação'), findsOneWidget);
    expect(find.textContaining('não informado'), findsNothing);
    expect(find.textContaining('Ação e Aventura'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
