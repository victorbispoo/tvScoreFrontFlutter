import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/season_selector.dart';

void main() {
  testWidgets('seleciona especiais, fecha fora e com Voltar', (tester) async {
    var selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topRight,
              child: SeasonSelector(
                seasons: const [0, 1, 2],
                value: selected,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();
    expect(find.text('Temporada 1'), findsOneWidget);
    await tester.tap(find.text('Especiais'));
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(find.byKey(const ValueKey('season-menu')), findsNothing);
    await tester.tap(find.text('Especiais'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('season-menu')), findsNothing);
    await tester.tap(find.text('Especiais'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('season-menu')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menu sobe na borda inferior e rola muitas temporadas com fonte grande',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var selected = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Align(
                alignment: Alignment.bottomRight,
                child: SeasonSelector(
                  seasons: List.generate(60, (i) => i + 1),
                  value: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      final anchor = tester.getRect(find.byType(SeasonSelector));
      await tester.tap(find.text('T1'));
      await tester.pumpAndSettle();
      final menu = tester.getRect(find.byKey(const ValueKey('season-menu')));
      expect(menu.bottom, lessThanOrEqualTo(anchor.top - 7));
      expect(menu.left, greaterThanOrEqualTo(12));
      expect(menu.right, lessThanOrEqualTo(308));
      expect(menu.height, lessThanOrEqualTo(320));
      await tester.scrollUntilVisible(
        find.text('Temporada 60'),
        200,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temporada 60'));
      await tester.pumpAndSettle();
      expect(selected, 60);
      expect(find.text('T60'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('overlay acompanha a posição do botão na rolagem', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 150),
              Align(
                alignment: Alignment.centerRight,
                child: SeasonSelector(
                  seasons: const [1, 2],
                  value: 1,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(const ValueKey('season-menu')));
    controller.jumpTo(50);
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.byKey(const ValueKey('season-menu')));
    expect(after.dy, closeTo(before.dy - 50, 1));
    expect(tester.takeException(), isNull);
  });
}
