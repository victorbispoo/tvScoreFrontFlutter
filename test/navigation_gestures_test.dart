import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('barra seleciona por toque e arraste apenas ao soltar', (
    tester,
  ) async {
    final selections = <int>[];
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: StatefulBuilder(
          builder: (context, update) => Scaffold(
            bottomNavigationBar: FloatingNavigationBar(
              index: selected,
              onSelected: (index) => update(() {
                selections.add(index);
                selected = index;
              }),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(
      tester
          .widget<Positioned>(
            find.byKey(const ValueKey('navigation-indicator')),
          )
          .left,
      greaterThan(5),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Favoritos')),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(470, 0));
    await tester.pump();
    expect(selections, [1]);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [1, 2]);
    expect(selected, 2);
  });

  testWidgets(
    'arraste cancelado volta ao início e indicador respeita limites',
    (tester) async {
      final selections = <int>[];
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generate,
          home: Scaffold(
            bottomNavigationBar: FloatingNavigationBar(
              index: 0,
              onSelected: selections.add,
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Início')),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(2000, 0));
      await tester.pump();
      final barWidth =
          tester.getSize(find.byType(FloatingNavigationBar)).width - 40;
      final slotWidth = barWidth / 3;
      expect(
        tester
            .widget<Positioned>(
              find.byKey(const ValueKey('navigation-indicator')),
            )
            .left,
        closeTo(slotWidth * 2 + 5, 2),
      );
      expect(selections, isEmpty);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Positioned>(
              find.byKey(const ValueKey('navigation-indicator')),
            )
            .left,
        5,
      );
      expect(selections, isEmpty);
    },
  );

  testWidgets('swipe e toque mantêm página e indicador sincronizados', (
    tester,
  ) async {
    final feedback = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          feedback.add(call.arguments as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().open('gestos@teste.com', 'Teste');
    ApiService.token = 'test-token';
    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: AppShell()),
    );
    await tester.pumpAndSettle();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final layout = find.descendant(
      of: find.byType(FloatingNavigationBar),
      matching: find.byType(LayoutBuilder),
    );
    final slot = tester.getSize(layout).width / 3;
    void expectConnected() {
      expect(
        tester.widget<Positioned>(indicator).left,
        closeTo(5 + controller.page! * slot, .01),
      );
      final actual =
          tester
              .getTopLeft(
                find.descendant(
                  of: indicator,
                  matching: find.byType(DecoratedBox),
                ),
              )
              .dx -
          tester.getTopLeft(layout).dx;
      expect(actual, closeTo(5 + controller.page! * slot, .01));
    }

    for (final fraction in [
      .25,
      .5,
      .75,
      1.25,
      1.5,
      1.75,
      1.5,
      1.25,
      .75,
      .25,
      0.0,
    ]) {
      controller.jumpTo(fraction * controller.position.viewportDimension);
      await tester.pump();
      expectConnected();
    }
    // Check rendered geometry on each gesture frame, including crossing an index.
    for (final start in [0, 1, 2]) {
      controller.jumpToPage(start);
      await tester.pumpAndSettle();
      final direction = start == 2 ? 1.0 : -1.0;
      final slow = await tester.startGesture(
        tester.getTopLeft(find.byType(PageView)) + const Offset(400, 90),
      );
      await slow.moveBy(Offset(direction * 30, 0));
      await tester.pump();
      for (var step = 0; step < 3; step++) {
        await slow.moveBy(
          Offset(direction * controller.position.viewportDimension / 4, 0),
        );
        await tester.pump(const Duration(milliseconds: 16));
        expectConnected();
        final held = controller.page;
        await tester.pump(const Duration(milliseconds: 100));
        expect(controller.page, held);
        expectConnected();
      }
      await slow.up();
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expectConnected();
      }
      await tester.pumpAndSettle();
      expect(controller.page, start - direction);
    }
    controller.jumpToPage(0);
    await tester.pumpAndSettle();
    // A short, slow swipe returns to its starting page without releasing alignment.
    final canceled = await tester.startGesture(
      tester.getTopLeft(find.byType(PageView)) + const Offset(600, 90),
    );
    await canceled.moveBy(const Offset(-30, 0));
    await tester.pump();
    await canceled.moveBy(const Offset(-150, 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.page, greaterThan(0));
    expectConnected();
    await canceled.up();
    await tester.pumpAndSettle();
    expect(controller.page, 0);
    expectConnected();

    expect(feedback, isEmpty);
    final capsule = await tester.startGesture(
      tester.getCenter(find.text('In\u00edcio')),
    );
    await capsule.moveBy(const Offset(30, 0));
    await tester.pump();
    await capsule.moveBy(Offset(slot * .8, 0));
    await tester.pump();
    expectConnected();
    expect(controller.page, greaterThan(.5));
    final heldCapsulePage = controller.page;
    await tester.pump(const Duration(milliseconds: 150));
    expect(controller.page, heldCapsulePage);
    expectConnected();
    final beforeRelease = tester.widget<Positioned>(indicator).left!;
    await capsule.up();
    await tester.pump();
    expect(
      tester.widget<Positioned>(indicator).left,
      closeTo(beforeRelease, .01),
    );
    expectConnected();
    await tester.pumpAndSettle();
    expect(controller.page, 1);
    expect(feedback, ['HapticFeedbackType.selectionClick']);
    await tester.tap(find.text('In\u00edcio'));
    await tester.pumpAndSettle();

    final canceledCapsule = await tester.startGesture(
      tester.getCenter(find.text('In\u00edcio')),
    );
    await canceledCapsule.moveBy(const Offset(30, 0));
    await tester.pump();
    await canceledCapsule.moveBy(Offset(slot * .75, 0));
    await tester.pump();
    expect(controller.page, greaterThan(.5));
    expectConnected();
    await canceledCapsule.cancel();
    await tester.pumpAndSettle();
    expect(controller.page, 0);
    expectConnected();

    Future<void> swipe(double distance) async {
      final origin =
          tester.getTopLeft(find.byType(PageView)) + const Offset(240, 90);
      final gesture = await tester.startGesture(origin);
      await gesture.moveBy(Offset(distance.sign * 30, 0));
      await tester.pump();
      await gesture.moveBy(Offset(distance - distance.sign * 30, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await swipe(-550);
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      1,
    );
    await swipe(-550);
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      2,
    );
    await swipe(550);
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      1,
    );
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      0,
    );
    await tester.tap(find.text('Perfil'));
    await tester.pump();
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectConnected();
    }
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      2,
    );
    // Starting a capsule drag interrupts an in-flight tap animation.
    await tester.tap(find.text('In\u00edcio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final bar = tester.widget<FloatingNavigationBar>(
      find.byType(FloatingNavigationBar),
    );
    final label = ['In\u00edcio', 'Favoritos', 'Perfil'][bar.index];
    final interrupt = await tester.startGesture(
      tester.getCenter(
        find.descendant(
          of: find.byType(FloatingNavigationBar),
          matching: find.text(label),
        ),
      ),
    );
    await interrupt.moveBy(const Offset(30, 0));
    await tester.pump();
    final heldPage = controller.page!;
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.page, closeTo(heldPage, .001));
    await interrupt.moveBy(Offset(-slot * .2, 0));
    await tester.pump();
    final heldIndicator = tester.widget<Positioned>(indicator).left!;
    await interrupt.up();
    await tester.pump();
    expect(
      tester.widget<Positioned>(indicator).left,
      closeTo(heldIndicator, .01),
    );
    expectConnected();
    await tester.pumpAndSettle();
    expectConnected();

    controller.jumpToPage(0);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.tap(find.text('In\u00edcio'));
    await tester.pumpAndSettle();
    expect(controller.page, 0);

    expect(
      backend.requests.where((request) => request == 'GET /avaliacoes/minhas'),
      hasLength(1),
    );
    expect(find.byType(HomePage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('arraste do Perfil encaixa na aba mais próxima', (tester) async {
    final selections = <int>[];
    var selected = 2;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: StatefulBuilder(
          builder: (context, update) => Scaffold(
            bottomNavigationBar: FloatingNavigationBar(
              index: selected,
              onSelected: (index) => update(() {
                selections.add(index);
                selected = index;
              }),
            ),
          ),
        ),
      ),
    );

    final profile = tester.getCenter(find.text('Perfil'));
    final stay = await tester.startGesture(profile);
    await stay.moveBy(const Offset(-25, 0));
    await tester.pump();
    await stay.moveBy(const Offset(-60, 0));
    await stay.up();
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(selections, isEmpty);

    final move = await tester.startGesture(profile);
    await move.moveBy(const Offset(-30, 0));
    await tester.pump();
    await move.moveBy(const Offset(-230, 0));
    await move.up();
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(selections, [1]);
  });

  testWidgets('indicador retorna à aba ativa se navegação for interrompida', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: Scaffold(
          bottomNavigationBar: FloatingNavigationBar(
            index: 0,
            onSelected: selections.add,
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Início')),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(250, 0));
    await gesture.up();
    await tester.pump();
    expect(selections, [1]);
    await tester.pump(const Duration(milliseconds: 401));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Positioned>(
            find.byKey(const ValueKey('navigation-indicator')),
          )
          .left,
      5,
    );
  });

  testWidgets('carrossel horizontal mantém a aba e Home preserva rolagem', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().open('carrossel@teste.com', 'Teste');
    ApiService.token = 'test-token';
    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: AppShell()),
    );
    await tester.pumpAndSettle();

    final carousel = find
        .byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        )
        .first;
    final carouselScroll = tester.state<ScrollableState>(
      find.descendant(of: carousel, matching: find.byType(Scrollable)).first,
    );
    await tester.drag(carousel, const Offset(-220, 0));
    await tester.pumpAndSettle();
    expect(carouselScroll.position.pixels, greaterThan(0));
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      0,
    );
    await tester.drag(carousel, const Offset(2000, 0));
    await tester.pumpAndSettle();
    await tester.drag(carousel, const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      0,
    );

    final homeList = find
        .descendant(
          of: find.byType(HomePage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.vertical,
          ),
        )
        .first;
    await tester.drag(homeList, const Offset(0, -500));
    await tester.pumpAndSettle();
    final homeScroll = tester.state<ScrollableState>(
      find.descendant(of: homeList, matching: find.byType(Scrollable)).first,
    );
    final offset = homeScroll.position.pixels;
    expect(offset, greaterThan(0));
    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(homeScroll.position.pixels, closeTo(offset, 1));

    final card = find.byType(ContentCard).first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final offsetBeforeDetails = homeScroll.position.pixels;
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
          .index,
      0,
    );
    expect(homeScroll.position.pixels, closeTo(offsetBeforeDetails, 1));
  });
}
