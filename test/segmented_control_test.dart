import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_segmented_control.dart';

const options = {0: 'Todos', 1: 'Filmes', 2: 'Séries'};

void main() {
  final feedback = <String>[];
  setUp(() {
    feedback.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            feedback.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  testWidgets(
    'toque confirma uma vez e valor igual não repete callback ou háptico',
    (tester) async {
      var selected = 0;
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, update) => Scaffold(
              body: TvScoreSegmentedControl<int>(
                options: options,
                selectedValue: selected,
                onChanged: (value) => update(() {
                  selected = value;
                  changes.add(value);
                }),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filmes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filmes'));
      expect(changes, [1]);
      expect(feedback, hasLength(1));
    },
  );

  for (final target in [1, 2]) {
    testWidgets('arraste contínuo até $target confirma somente ao soltar', (
      tester,
    ) async {
      var selected = 0;
      var parentBuilds = 0;
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, update) {
              parentBuilds++;
              return Scaffold(
                body: TvScoreSegmentedControl<int>(
                  options: options,
                  selectedValue: selected,
                  onChanged: (value) => update(() {
                    selected = value;
                    changes.add(value);
                  }),
                ),
              );
            },
          ),
        ),
      );
      final builds = parentBuilds;
      final control = find.byType(TvScoreSegmentedControl<int>);
      final slot = tester.getSize(control).width / 3;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Todos')),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      for (var step = 0; step < target * 4; step++) {
        await gesture.moveBy(Offset(slot / 4, 0));
        await tester.pump(const Duration(milliseconds: 16));
        final indicator = find.byKey(const ValueKey('segmented-indicator'));
        final left =
            tester.getTopLeft(indicator).dx - tester.getTopLeft(control).dx;
        expect(left, closeTo(3 + slot * (step + 1) / 4, .01));
        expect(changes, isEmpty);
        expect(selected, 0);
      }
      expect(parentBuilds, builds);
      expect(feedback, hasLength(target));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes, [target]);
      expect(feedback, hasLength(target));
    });
  }

  testWidgets('limites, direção inversa e cancelamento restauram seleção', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvScoreSegmentedControl<int>(
            options: options,
            selectedValue: 2,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    final control = find.byType(TvScoreSegmentedControl<int>);
    final indicator = find.byKey(const ValueKey('segmented-indicator'));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Séries')),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-2000, 0));
    await tester.pump();
    expect(tester.getTopLeft(indicator).dx - tester.getTopLeft(control).dx, 3);
    expect(changes, isEmpty);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(indicator).dx - tester.getTopLeft(control).dx,
      closeTo(3 + tester.getSize(control).width * 2 / 3, .01),
    );
    expect(changes, isEmpty);
    await tester.drag(find.text('S\u00e9ries'), const Offset(-2000, 0));
    await tester.pumpAndSettle();
    expect(changes, [0]);
  });

  testWidgets(
    'duas opções encaixam na mais próxima e ignoram opção já selecionada',
    (tester) async {
      var selected = false;
      final changes = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, update) => Scaffold(
              body: TvScoreSegmentedControl<bool>(
                options: const {false: 'Mais recentes', true: 'Maiores notas'},
                selectedValue: selected,
                onChanged: (value) => update(() {
                  selected = value;
                  changes.add(value);
                }),
              ),
            ),
          ),
        ),
      );
      for (final distance in [30.0, 70.0]) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Mais recentes')),
        );
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await gesture.moveBy(Offset(distance, 0));
        await tester.pump();
        expect(changes, isEmpty);
        await gesture.up();
        await tester.pumpAndSettle();
      }
      expect(changes, [true]);
      expect(feedback, hasLength(1));
    },
  );

  testWidgets(
    'pai altera seleção durante arraste e mantém a seleção definitiva',
    (tester) async {
      var selected = 0;
      late StateSetter updateParent;
      final changes = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, update) {
              updateParent = update;
              return Scaffold(
                body: TvScoreSegmentedControl<int>(
                  options: options,
                  selectedValue: selected,
                  onChanged: changes.add,
                ),
              );
            },
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Todos')),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      updateParent(() => selected = 2);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      final indicator = tester.widget<PositionedDirectional>(
        find.byKey(const ValueKey('segmented-indicator')),
      );
      expect(indicator.start, 227);
    },
  );

  testWidgets('controle vence PageView e preserva gesto fora de sua área', (
    tester,
  ) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageView(
            controller: pages,
            children: [
              Column(
                children: [
                  TvScoreSegmentedControl<int>(
                    options: options,
                    selectedValue: 0,
                    onChanged: changes.add,
                  ),
                  const Expanded(child: ColoredBox(color: Colors.black)),
                ],
              ),
              const ColoredBox(color: Colors.blue),
            ],
          ),
        ),
      ),
    );
    await tester.drag(find.text('Todos'), const Offset(230, 0));
    await tester.pumpAndSettle();
    expect(changes, [2]);
    expect(pages.page, 0);
    await tester.dragFrom(const Offset(500, 300), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(pages.page, 1);
  });

  testWidgets('rótulos grandes, alvos acessíveis e teclado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: TvScoreSegmentedControl<bool>(
                options: const {false: 'Mais recentes', true: 'Maiores notas'},
                selectedValue: false,
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    for (final button in tester.widgetList<TextButton>(
      find.byType(TextButton),
    )) {
      expect(
        button.style!.minimumSize!.resolve({})!.height,
        greaterThanOrEqualTo(48),
      );
    }
    Focus.of(tester.element(find.text('Maiores notas'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, [true]);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
