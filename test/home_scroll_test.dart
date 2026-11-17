import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

import 'support/backend_http.dart';

class _HomeBackend extends BackendHttp {
  _HomeBackend(this.preferredCount);
  final int preferredCount;
  int genreLoads = 0;

  @override
  Object? respond(String method, Uri uri, String body) {
    final genres = [
      for (var i = 0; i < 6; i++) {'codigo': 'genre$i', 'nome': 'Genre $i'},
    ];
    if (uri.path.endsWith('/conteudos/generos')) {
      genreLoads++;
      return genres;
    }
    if (uri.path.endsWith('/usuarios/eu/generos')) {
      return {'generos': genres.take(preferredCount).toList()};
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  for (final preferredCount in [0, 5]) {
    testWidgets(
      'Home leaves bottom without opposing drags, $preferredCount preferred genres',
      (tester) async {
        final backend = _HomeBackend(preferredCount);
        final previous = HttpOverrides.current;
        HttpOverrides.global = backend;
        addTearDown(() => HttpOverrides.global = previous);
        ApiService.token = 'test-token';
        await tester.binding.setSurfaceSize(const Size(600, 780));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: HomePage()),
          ),
        );
        await tester.pumpAndSettle();
        final list = find.byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.vertical,
        );
        final position = tester
            .state<ScrollableState>(
              find
                  .descendant(of: list, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        for (var i = 0; i < 10; i++) {
          await tester.dragFrom(const Offset(195, 400), const Offset(0, -500));
          await tester.pumpAndSettle();
        }
        expect(position.extentAfter, closeTo(0, 1));
        for (var repeat = 0; repeat < 2; repeat++) {
          for (final distance in [60.0, 320.0, 600.0]) {
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
            final before = position.pixels;
            final gesture = await tester.startGesture(const Offset(195, 300));
            await gesture.moveBy(const Offset(0, 25));
            await tester.pump(const Duration(milliseconds: 16));
            for (var step = 0; step < 6; step++) {
              final previousOffset = position.pixels;
              await gesture.moveBy(Offset(0, distance / 6));
              await tester.pump(const Duration(milliseconds: 32));
              expect(
                position.pixels,
                lessThanOrEqualTo(previousOffset + 1),
                reason:
                    'The list must follow the finger toward earlier sections.',
              );
            }
            final during = position.pixels;
            expect(during, lessThan(before));
            await gesture.up();
            await tester.pumpAndSettle();
            expect(position.pixels, lessThanOrEqualTo(during + 1));
          }
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final before = position.pixels;
          await tester.flingFrom(
            const Offset(195, 300),
            const Offset(0, 300),
            1800,
          );
          await tester.pumpAndSettle();
          expect(position.pixels, lessThan(before));
        }
        position.jumpTo(0);
        await tester.pumpAndSettle();
        final loads = backend.genreLoads;
        await tester.dragFrom(const Offset(195, 180), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(backend.genreLoads, loads + 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
