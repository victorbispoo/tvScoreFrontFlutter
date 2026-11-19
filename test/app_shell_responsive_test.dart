import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_breakpoints.dart';
import 'package:tv_score_front_flutter/core/app_shell.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/desktop_navigation.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/trending_carousel.dart';

import 'support/backend_http.dart';

void main() {
  test('breakpoints centralizados', () {
    expect(AppBreakpoints.tablet, 600);
    expect(AppBreakpoints.isDesktop(1023), isFalse);
    expect(AppBreakpoints.isDesktop(1024), isTrue);
  });

  for (final brightness in Brightness.values) {
    testWidgets('navegação e resize no tema $brightness', (tester) async {
      final previous = HttpOverrides.current;
      HttpOverrides.global = BackendHttp();
      FlutterSecureStorage.setMockInitialValues({});
      ApiService.token = 'responsive-test';
      ApiService.savedContents = [];
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        HttpOverrides.global = previous;
        ApiService.token = null;
        ApiService.savedContents = [];
        tester.view.reset();
      });
      tester.view.physicalSize = const Size(390, 650);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const AppShell(),
        ),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller;
      final homeState = tester.state(find.byType(HomePage));
      tester
          .widget<TrendingCarousel>(
            find.byType(TrendingCarousel, skipOffstage: false),
          )
          .onTypeSelected('TV');
      await tester.pumpAndSettle();
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(HomePage),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      scroll.jumpTo(10);
      await tester.pumpAndSettle();
      final offset = scroll.pixels;

      for (final width in [390.0, 768.0, 1024.0, 1366.0, 1920.0, 390.0]) {
        tester.view.physicalSize = Size(width, 650);
        await tester.pumpAndSettle();
        final desktop = width >= AppBreakpoints.desktop;
        expect(
          find.byType(DesktopNavigation),
          desktop ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(FloatingNavigationBar),
          desktop ? findsNothing : findsOneWidget,
        );
        expect(
          tester.widget<PageView>(find.byType(PageView)).controller,
          same(controller),
        );
        expect(tester.state(find.byType(HomePage)), same(homeState));
        expect(
          find.descendant(
            of: find.byType(HomePage),
            matching: find.byType(SvgPicture),
          ),
          desktop ? findsNothing : findsOneWidget,
        );
        if (desktop) {
          final sidebar = tester.getRect(find.byType(DesktopNavigation));
          expect(sidebar.top, 0);
          expect(sidebar.height, 650);
          final home = tester.getRect(find.byType(HomePage));
          expect(home.left, greaterThanOrEqualTo(sidebar.right));
          expect(home.right, lessThanOrEqualTo(width));
        }
        expect(scroll.pixels, offset);
        expect(
          tester
              .widget<TrendingCarousel>(
                find.byType(TrendingCarousel, skipOffstage: false),
              )
              .selectedType,
          'TV',
        );
        expect(
          tester.widget<HomePage>(find.byType(HomePage)).bottomPadding,
          desktop ? 0 : 88,
        );
        final navigation = find.byType(
          desktop ? DesktopNavigation : FloatingNavigationBar,
        );
        for (final (index, label) in [
          (1, 'Favoritos'),
          (2, 'Perfil'),
          (0, 'Início'),
        ]) {
          await tester.tap(
            find.descendant(of: navigation, matching: find.text(label)),
          );
          await tester.pumpAndSettle();
          expect(controller!.page, index.toDouble());
          expect(
            find.byType([HomePage, FavoritesPage, ProfilePage][index]),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
