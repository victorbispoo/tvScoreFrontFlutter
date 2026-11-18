import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/where_to_watch.dart';

import 'content_genres_test.dart' show apiReturning;
import 'support/backend_http.dart';

void main() {
  for (final (type, brightness) in [
    ('MOVIE', Brightness.light),
    ('TV', Brightness.dark),
  ]) {
    testWidgets('$type availability at 280 dp in $brightness', (tester) async {
      await tester.binding.setSurfaceSize(const Size(280, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final availability = {
        'link': 'https://www.themoviedb.org/watch',
        'assinatura': [
          {
            'provider_id': 8,
            'provider_name': 'Netflix',
            'logo_path': '/valid.png',
          },
          {'provider_id': 9, 'provider_name': 'Streaming B'},
        ],
        'comAnuncios': [
          {
            'provider_id': 10,
            'provider_name': 'Streaming C',
            'logo_path': 'invalid',
          },
        ],
        'gratis': [
          {'provider_id': 8, 'provider_name': 'Netflix'},
        ],
        'aluguel': [
          {'provider_id': 11, 'provider_name': 'Streaming B'},
          {
            'provider_id': 12,
            'provider_name': 'Plataforma com nome completo e comprido',
          },
        ],
      };
      final content = (await tester.runAsync(
        () => apiReturning({
          'id': 123,
          'ondeAssistir': availability,
        }).getContent(123, type),
      ))!;
      expect(jsonDecode(content['ondeAssistir']!), availability);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(body: WhereToWatch(content['ondeAssistir'])),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assinatura'), findsNothing);
      expect(find.text('Streaming C'), findsNothing);
      expect(find.text('Netflix'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
      expect(find.byType(Tooltip), findsNWidgets(3));
      expect(find.byIcon(Icons.live_tv_outlined), findsNWidgets(3));
      await tester.tap(find.text('Ver opções'));
      await tester.pumpAndSettle();
      expect(find.text('Assinatura'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      final sheetList = find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Grátis').hitTestable(),
        105,
        scrollable: sheetList,
      );
      expect(find.text('Grátis').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Ver disponibilidade no TMDB'),
        150,
        scrollable: sheetList,
      );
      expect(find.text('Streaming B'), findsWidgets);
      expect(
        tester
            .widget<Text>(find.text('Plataforma com nome completo e comprido'))
            .maxLines,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing providers and unsafe links are handled', (tester) async {
    for (final value in [
      null,
      '{}',
      '[]',
      '{',
      '{"link":"javascript:alert(1)","compra":[]}',
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WhereToWatch(value))),
      );
      expect(
        find.text('Disponibilidade não informada para o Brasil'),
        findsOneWidget,
      );
      expect(find.text('Ver opções'), findsNothing);
      expect(find.text('Compra'), findsNothing);
    }
  });

  for (final count in [1, 3]) {
    testWidgets('mostra $count logos sem contador', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WhereToWatch(
              jsonEncode({
                'compra': [
                  for (var i = 0; i < count; i++)
                    {'provider_id': i + 1, 'provider_name': 'Provedor $i'},
                ],
              }),
            ),
          ),
        ),
      );
      expect(find.byType(Tooltip), findsNWidgets(count));
      expect(find.textContaining('+'), findsNothing);
      expect(find.text('Disponível para compra'), findsOneWidget);
    });
  }

  for (final (title, rated) in [
    ('Frieren e a Jornada para o Além', true),
    ('Um filme', false),
  ]) {
    testWidgets('mantém metadados e notas em grupos para $title', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final backend = BackendHttp();
      if (rated) {
        backend.communityReviews.add({
          'id': 1,
          'filmeSerieId': 42,
          'tipoConteudo': 'MOVIE',
          'nota': 9.0,
          'comentario': '',
          'dataCriacao': '2026-01-01T12:00:00',
        });
      }
      final previous = HttpOverrides.current;
      HttpOverrides.global = backend;
      addTearDown(() => HttpOverrides.global = previous);
      ApiService.token = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: rated ? ThemeData.dark() : ThemeData.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: DetailsPage(
            content: {
              'id': '42',
              'type': 'MOVIE',
              'title': title,
              'year': '2024',
              'genre': 'Animação • Aventura • Fantasia • Drama • Mistério',
              'score': '8.8',
              'overview': 'Sinopse do conteúdo',
              'ondeAssistir': '{}',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tmdb = find.text('TMDB:\u00a08.8/10');
      final tvScore = find.text(
        rated ? 'TVScore:\u00a09.0/10' : 'TVScore: sem avaliações',
      );
      expect(find.text(title), findsOneWidget);
      expect(
        find.text('2024 • Animação • Aventura • Fantasia • Drama • Mistério'),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: tmdb, matching: find.byType(Row)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: tvScore, matching: find.byType(Row)),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Onde assistir')).dy,
        lessThan(tester.getTopLeft(find.text('Sinopse do conteúdo')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
