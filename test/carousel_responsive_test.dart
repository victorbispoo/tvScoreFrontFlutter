import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/carousel_viewport.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/content_poster.dart';
import 'package:tv_score_front_flutter/widgets/ranked_content_carousel.dart';

void main() {
  final contents = List.generate(
    12,
    (index) => {
      'id': '$index',
      'type': 'MOVIE',
      'title': 'Uma história de cinema com um título longo $index',
      'poster_path': '',
      'year': '2026',
      'score': '8.5',
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('carrosséis desktop, mouse e resize em $brightness', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final width in [390.0, 768.0, 1024.0, 1366.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 1100);
        final desktop = width >= 1024;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: desktop ? (width - 232).clamp(0, 1336) : width,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ContentCarousel(
                          title: 'Cinema',
                          contents: contents,
                          onChanged: () {},
                        ),
                        RankedContentCarousel(
                          contents: contents,
                          onChanged: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byType(ContentCard).first;
        final cardWidth = tester.getSize(card).width;
        expect(cardWidth, desktop ? greaterThanOrEqualTo(160) : 144);
        final poster = find.descendant(
          of: card,
          matching: find.byType(ContentPoster),
        );
        final size = tester.getSize(poster);
        expect(size.width / size.height, closeTo(2 / 3, .001));
        expect(
          find.byTooltip('Próximos'),
          desktop ? findsNWidgets(2) : findsNothing,
        );
        final viewport = find.byType(CarouselViewport).first;
        final list = find.descendant(
          of: viewport,
          matching: find.byType(ListView),
        );
        final controller = tester.widget<ListView>(list).controller!;
        controller.jumpTo(0);
        await tester.pumpAndSettle();
        if (desktop) {
          await tester.tap(find.byTooltip('Próximos').first);
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(0));
          await tester.tap(find.byTooltip('Anteriores').first);
          await tester.pumpAndSettle();
          expect(controller.offset, 0);
          await tester.drag(
            list,
            const Offset(-150, 0),
            kind: PointerDeviceKind.mouse,
          );
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(0));
          final before = controller.offset;
          await tester.sendEventToBinding(
            PointerScrollEvent(
              position: tester.getCenter(list),
              scrollDelta: const Offset(120, 0),
            ),
          );
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(before));
        }
        if (desktop) {
          final offsetBeforeNavigation = controller.offset;
          final navigator = Navigator.of(tester.element(viewport));
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Outra tela')),
            ),
          );
          await tester.pumpAndSettle();
          navigator.pop();
          await tester.pumpAndSettle();
          expect(controller.offset, offsetBeforeNavigation);
        }
        final offset = controller.offset;
        tester.view.physicalSize = Size(width + 1, 1100);
        await tester.pumpAndSettle();
        expect(tester.widget<ListView>(list).controller, same(controller));
        expect(controller.offset, offset);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
