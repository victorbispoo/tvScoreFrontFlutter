import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/where_to_watch.dart';

import 'content_genres_test.dart' show apiReturning;

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
          home: Scaffold(body: WhereToWatch(content['ondeAssistir'])),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assinatura'), findsNothing);
      expect(find.text('Streaming C'), findsOneWidget);
      expect(find.text('Grátis'), findsNothing);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.byIcon(Icons.live_tv_outlined), findsNWidgets(3));
      expect(
        tester
            .widgetList<InkWell>(find.byType(InkWell))
            .where((tile) => tile.onTap != null),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing providers and unsafe links are handled', (tester) async {
    for (final value in [
      null,
      '{}',
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
}
