import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/cinematic_poster_composition.dart';

import '../tool/cinematic_glow_preview.dart';

class _UnavailableBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(StateError('Asset indisponível no teste'));
}

void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}

Finder _rotations(Finder composition) => find.descendant(
  of: composition,
  matching: find.byWidgetPredicate(
    (widget) => widget is Transform && widget.transform.entry(0, 1) != 0,
  ),
);

Finder _translations(Finder composition) => find.descendant(
  of: composition,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Transform &&
        widget.transform.entry(0, 1) == 0 &&
        widget.transform.entry(1, 0) == 0,
  ),
);

bool _isPoster(Positioned position) =>
    position.width != null && position.height == position.width! * 1.5;

void main() {
  for (final count in [4, 5]) {
    testWidgets(
      '$count pôsteres: composição fixa, assimétrica e proporcional',
      (tester) async {
        _reduceMotion(tester);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final width in [320.0, 768.0, 1366.0, 1920.0]) {
          tester.view.physicalSize = Size(width, 1000);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 1000,
                    child: CinematicPosterComposition(placeholderCount: count),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final composition = find.byType(CinematicPosterComposition);
          final transforms = _rotations(composition);
          expect(transforms, findsNWidgets(count));
          final frames = find.descendant(
            of: composition,
            matching: find.byType(ClipRRect),
          );
          expect(frames, findsNWidgets(count));
          for (final frame in frames.evaluate()) {
            final size = tester.getSize(
              find.byElementPredicate((element) => element == frame),
            );
            expect(size.width / size.height, closeTo(2 / 3, .0001));
          }
          for (final transform in tester.widgetList<Transform>(transforms)) {
            final angle =
                math.atan2(
                  transform.transform.entry(1, 0),
                  transform.transform.entry(0, 0),
                ) *
                180 /
                math.pi;
            expect(angle, inInclusiveRange(-12, 12));
            expect(angle, isNot(0));
          }
          final placements = tester
              .widgetList<Positioned>(
                find.descendant(
                  of: composition,
                  matching: find.byType(Positioned),
                ),
              )
              .where(_isPoster)
              .toList();
          expect(placements.map((p) => p.top).toSet().length, count);
          expect(placements.map((p) => p.width).toSet().length, count);
          final rects = placements
              .map((p) => Rect.fromLTWH(p.left!, p.top!, p.width!, p.height!))
              .toList();
          expect([
            for (var i = 0; i < count; i++)
              for (var j = i + 1; j < count; j++) rects[i].overlaps(rects[j]),
          ], contains(true));
          expect(
            find.descendant(of: composition, matching: find.byType(Image)),
            findsNothing,
          );
          expect(find.text('Asset local pendente'), findsNWidgets(count));
          expect(tester.getSize(composition).width, lessThanOrEqualTo(width));
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('aceita assets locais explícitos sem buscar imagens na rede', (
    tester,
  ) async {
    _reduceMotion(tester);
    // The existing logo is only an image-loading fixture, never preview artwork.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CinematicPosterComposition(
            posterAssets: List.filled(4, 'lib/assets/logoTvScore.png'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images, hasLength(4));
    expect(images.every((image) => image.image is AssetImage), isTrue);
    expect(find.text('Asset local pendente'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'seleção parcial mantém Duna no centro e identifica os demais títulos',
    (tester) async {
      _reduceMotion(tester);
      // Existing logo is an image-loading fixture only, not a selected poster.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CinematicPosterComposition(
              posterAssets: const [
                null,
                null,
                'lib/assets/logoTvScore.png',
                null,
                null,
              ],
              posterTitles: [
                for (final poster in CinematicPosterComposition.featuredPosters)
                  poster.title,
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Asset local pendente'), findsNWidgets(4));
      for (final title in [
        'Interestelar',
        'Breaking Bad',
        'Stranger Things',
        'The Batman',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      final center = find
          .ancestor(of: find.byType(Image), matching: find.byType(Positioned))
          .first;
      expect(tester.widget<Positioned>(center).width, 222);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falha de asset é visível sem substituir por imagem remota', (
    tester,
  ) async {
    _reduceMotion(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefaultAssetBundle(
            bundle: _UnavailableBundle(),
            child: CinematicPosterComposition(
              posterAssets: List.filled(4, 'lib/assets/logoTvScore.png'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Imagem indisponível'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview loads five local posters with central Dune', (
    tester,
  ) async {
    _reduceMotion(tester);
    await tester.pumpWidget(const CinematicGlowPreview());
    await tester.pumpAndSettle();
    final composition = find.byType(CinematicPosterComposition);
    expect(find.textContaining('Assets locais pendentes'), findsNothing);
    for (final poster in CinematicPosterComposition.featuredPosters) {
      expect(find.image(AssetImage(poster.asset)), findsOneWidget);
    }
    final placements = tester
        .widgetList<Positioned>(
          find.descendant(of: composition, matching: find.byType(Positioned)),
        )
        .where(_isPoster)
        .toList();
    final dune = find
        .ancestor(
          of: find.image(
            const AssetImage('lib/assets/cinematic_dune_part_two.webp'),
          ),
          matching: find.byType(Positioned),
        )
        .first;
    expect(tester.widget<Positioned>(dune), same(placements.last));
    expect(
      placements.last.width,
      placements.map((p) => p.width!).reduce(math.max),
    );
    // Most of each rear poster remains exposed, rather than hidden by the hero.
    final rects = placements
        .map((p) => Rect.fromLTWH(p.left!, p.top!, p.width!, p.height!))
        .toList();
    for (var i = 0; i < rects.length - 1; i++) {
      var coveredArea = 0.0;
      for (var j = i + 1; j < rects.length; j++) {
        if (rects[i].overlaps(rects[j])) {
          final overlap = rects[i].intersect(rects[j]);
          coveredArea += overlap.width * overlap.height;
        }
      }
      expect(coveredArea / (rects[i].width * rects[i].height), lessThan(.30));
    }
    expect(find.byType(Image), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'flutuação começa em zero, tem ritmos distintos e retorna suavemente',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 900, child: CinematicPosterComposition()),
          ),
        ),
      );
      final composition = find.byType(CinematicPosterComposition);
      final translations = _translations(composition);
      final rotations = tester
          .widgetList<Transform>(_rotations(composition))
          .toList();
      final frames = tester
          .widgetList<ClipRRect>(
            find.descendant(of: composition, matching: find.byType(ClipRRect)),
          )
          .toList();
      final controllers = tester
          .widgetList<AnimatedBuilder>(
            find.descendant(
              of: composition,
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .map((builder) => builder.animation)
          .whereType<AnimationController>()
          .toList();
      expect(controllers.toSet(), hasLength(5));
      expect(controllers.map((c) => c.duration).toSet(), hasLength(5));
      for (final controller in controllers) {
        expect(
          controller.duration!.inMilliseconds,
          inInclusiveRange(5000, 8000),
        );
      }
      List<double> offsets() =>
          tester.widgetList<Transform>(translations).map((w) {
            expect(w.transform.entry(0, 3), 0);
            return w.transform.entry(1, 3);
          }).toList();
      expect(offsets(), everyElement(0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        offsets().map((value) => value.abs()),
        everyElement(lessThan(.001)),
      );
      await tester.pump(const Duration(milliseconds: 1199));
      expect(offsets().toSet(), hasLength(5));
      await tester.pump(const Duration(milliseconds: 4000));
      expect(offsets().first, closeTo(-6, .01));
      await tester.pump(const Duration(milliseconds: 2600));
      expect(offsets().last, closeTo(-7, .01));
      expect(offsets().first, greaterThan(-6));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
        expect(offsets(), everyElement(inInclusiveRange(-10, 0)));
      }
      final currentRotations = tester
          .widgetList<Transform>(_rotations(composition))
          .toList();
      final currentFrames = tester
          .widgetList<ClipRRect>(
            find.descendant(of: composition, matching: find.byType(ClipRRect)),
          )
          .toList();
      for (var i = 0; i < 5; i++) {
        expect(currentRotations[i], same(rotations[i]));
        expect(currentFrames[i], same(frames[i]));
      }
      expect(
        find.descendant(
          of: composition,
          matching: find.byType(RepaintBoundary),
        ),
        findsNWidgets(5),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(controllers.every((c) => !c.isAnimating), isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('movimento reduzido para tickers e reativação começa sem salto', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CinematicPosterComposition())),
    );
    final translations = _translations(find.byType(CinematicPosterComposition));
    List<double> offsets() => tester
        .widgetList<Transform>(translations)
        .map((w) => w.transform.entry(1, 3))
        .toList();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(offsets().any((value) => value != 0), isTrue);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    await tester.pumpAndSettle();
    expect(offsets(), everyElement(0));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pump(const Duration(seconds: 20));
    expect(offsets(), everyElement(0));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: false);
    await tester.pump();
    expect(offsets(), everyElement(0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(offsets().map((value) => value.abs()), everyElement(lessThan(.001)));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
