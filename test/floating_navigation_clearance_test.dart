import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/app_shell.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';

import 'support/backend_http.dart';

class _ClearanceBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/conteudos/por-genero')) {
      return {
        'results': [
          details({
            ...catalog.first,
            'id': '9000',
            'title': 'Última descoberta',
          }),
        ],
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  for (final (safeBottom, keyboard) in [
    (0.0, 0.0),
    (36.0, 0.0),
    (36.0, 180.0),
  ]) {
    testWidgets(
      'últimos itens acessíveis com área segura $safeBottom e teclado $keyboard',
      (tester) async {
        final backend = _ClearanceBackend();
        final saved = backend.catalog.take(8).toList();
        backend.favorites.addAll([
          for (final content in saved)
            {
              'filmeSerieId': int.parse(content['id']!),
              'tipoConteudo': content['type'],
            },
        ]);
        final previous = HttpOverrides.current;
        HttpOverrides.global = backend;
        FlutterSecureStorage.setMockInitialValues({});
        ApiService.token = 'clearance-test';
        ApiService.savedContents = [];
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(420, 650);
        tester.view.viewPadding = FakeViewPadding(bottom: safeBottom);
        tester.view.padding = FakeViewPadding(
          bottom: keyboard > 0 ? 0 : safeBottom,
        );
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        addTearDown(() {
          HttpOverrides.global = previous;
          ApiService.token = null;
          ApiService.savedContents = [];
          tester.view.reset();
        });
        await tester.pumpWidget(
          const MaterialApp(
            onGenerateRoute: AppRoutes.generate,
            home: AppShell(),
          ),
        );
        await tester.pumpAndSettle();

        final nav = find.byType(FloatingNavigationBar);
        Finder inPage(Type page, Finder child) =>
            find.descendant(of: find.byType(page), matching: child);
        Future<void> scrollToEnd(Type page) async {
          final position = tester
              .state<ScrollableState>(
                inPage(page, find.byType(Scrollable)).first,
              )
              .position;
          for (var i = 0; i < 4; i++) {
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
          }
        }

        void expectAboveBar(Finder item) {
          expect(item.hitTestable(), findsOneWidget);
          expect(
            tester.getBottomLeft(item).dy,
            lessThan(tester.getTopLeft(nav).dy),
          );
        }

        Future<void> selectTab(String title) async {
          await tester.tap(
            find.descendant(of: nav, matching: find.text(title)),
          );
          await tester.pumpAndSettle();
        }

        await scrollToEnd(HomePage);
        final expectedPadding = 650 - keyboard - tester.getTopLeft(nav).dy + 12;
        expect(
          tester.widget<HomePage>(find.byType(HomePage)).bottomPadding,
          expectedPadding,
        );
        final discovery = find.ancestor(
          of: find.text('Última descoberta'),
          matching: find.byType(ContentCard),
        );
        expectAboveBar(discovery);
        expectAboveBar(find.text('Descubra algo'));

        await selectTab('Favoritos');
        expect(
          tester
              .widget<FavoritesPage>(find.byType(FavoritesPage))
              .bottomPadding,
          expectedPadding,
        );
        await scrollToEnd(FavoritesPage);
        final favorite = find.ancestor(
          of: inPage(FavoritesPage, find.text(saved.last['title']!)),
          matching: find.byType(ContentCard),
        );
        expectAboveBar(favorite);
        await tester.tap(
          inPage(FavoritesPage, find.text(saved.last['title']!)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DetailsPage), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expectAboveBar(favorite);

        await selectTab('Perfil');
        expect(
          tester.widget<ProfilePage>(find.byType(ProfilePage)).bottomPadding,
          expectedPadding,
        );
        await scrollToEnd(ProfilePage);
        final logout = find.widgetWithText(TextButton, 'Sair da conta');
        expectAboveBar(logout);
        await tester.tap(logout);
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
