import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/trending_carousel.dart';

void main() {
  testWidgets('Em alta filtra filmes e séries sem overflow', (tester) async {
    final contents = [
      {
        'id': '1',
        'type': 'MOVIE',
        'title': 'Um filme',
        'year': '2026',
        'genre': 'Drama',
        'score': '8.0',
      },
      {
        'id': '2',
        'type': 'TV',
        'title': 'Uma série',
        'year': '2025',
        'genre': 'Comédia',
        'score': '7.5',
      },
    ];

    for (final width in [320.0, 390.0, 480.0]) {
      var filter = 'ALL';
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => TrendingCarousel(
                key: ValueKey(width),
                contents: contents
                    .where((item) => filter == 'ALL' || item['type'] == filter)
                    .toList(),
                selectedType: filter,
                onTypeSelected: (value) => setState(() => filter = value),
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Um filme'), findsOneWidget);
      await tester.tap(find.text('Séries'));
      await tester.pump();
      expect(find.text('Uma série'), findsOneWidget);
      expect(find.text('Um filme'), findsNothing);
    }
  });
}
