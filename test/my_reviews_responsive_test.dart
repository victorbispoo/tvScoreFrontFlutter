import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

import 'support/backend_http.dart';

final _longTitle = List.filled(
  12,
  'Uma história com um título extenso',
).join(' ');
const _shortTitle = 'Título curto';
const _lastTitle = 'Última avaliação';

Finder _card(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(ClipRRect)).first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    await ApiService().logout();
    ApiService.token = 'test-session';
    final previous = HttpOverrides.current;
    final backend = BackendHttp();
    backend.catalog.clear();
    for (final (index, title) in [
      _longTitle,
      _shortTitle,
      _lastTitle,
    ].indexed) {
      backend.catalog.add({
        'id': '${index + 1}',
        'type': 'MOVIE',
        'title': title,
        'year': '2024',
        'score': '8',
        'genre': 'Drama',
      });
      backend.reviews.add({
        'id': index + 1,
        'filmeSerieId': index + 1,
        'tipoConteudo': 'MOVIE',
        'nota': [7.5, 9.0, 6.0][index],
        'comentario': index == 0
            ? List.filled(100, 'Comentário extenso.').join(' ')
            : '',
        'dataCriacao': '2026-11-${19 - index}T12:00:00',
      });
    }
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
  });
  tearDown(() => ApiService().logout());

  for (final dark in [false, true]) {
    testWidgets(
      'reviews remain compact and responsive, dark=$dark',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1366, 1200);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const MyReviewsPage(),
          ),
        );
        await tester.pumpAndSettle();
        for (final width in [
          320.0,
          360.0,
          390.0,
          768.0,
          939.0,
          940.0,
          1024.0,
          1366.0,
          1920.0,
        ]) {
          tester.view.physicalSize = Size(width, 1200);
          await tester.pumpAndSettle();
          final list = tester.getRect(find.byType(ListView));
          final first = tester.getRect(_card(_longTitle));
          final second = tester.getRect(_card(_shortTitle));
          expect(list.width, lessThanOrEqualTo(1100));
          expect(list.center.dx, closeTo(width / 2, .01));
          expect(
            tester.getSize(find.byType(Card)).width,
            lessThanOrEqualTo(480),
          );
          expect(first.height, greaterThan(second.height));
          if (width >= 940) {
            expect(first.top, closeTo(second.top, .01));
            expect(second.left - first.right, closeTo(16, .01));
            expect(first.width, closeTo((list.width - 56) / 2, .01));
            final third = tester.getRect(_card(_lastTitle));
            expect(third.width, closeTo(first.width, .01));
            expect(third.top - first.bottom, closeTo(16, .01));
          } else {
            expect(second.left, closeTo(first.left, .01));
            expect(second.top - first.bottom, closeTo(16, .01));
          }
          expect(find.text('7.5/10'), findsOneWidget);
          expect(find.text('19/11/2026'), findsOneWidget);
          expect(find.text('Sua nota média'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.text('Maiores notas'));
        await tester.pumpAndSettle();
        final highest = tester.getRect(_card(_shortTitle));
        final next = tester.getRect(_card(_longTitle));
        expect(highest.top, closeTo(next.top, .01));
        expect(highest.left, lessThan(next.left));
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.windows,
      }),
    );
  }

  testWidgets('column count follows parent width on a wide desktop', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1920, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Center(child: SizedBox(width: 800, child: MyReviewsPage())),
      ),
    );
    await tester.pumpAndSettle();
    final first = tester.getRect(_card(_longTitle));
    final second = tester.getRect(_card(_shortTitle));
    expect(first.left, closeTo(second.left, .01));
    expect(second.top, greaterThan(first.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text and long comments fit a narrow screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const MyReviewsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text(_lastTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
