import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/models/search_filters.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/search_filter_sheet.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_confirmation_dialog.dart';

import 'support/backend_http.dart';

class _PreviewBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/conteudos-preferidos')) return {'conteudos': []};
    if (uri.path.endsWith('/conteudos-preferidos/opcoes')) {
      return {
        'results': [
          for (final item in catalog.take(4))
            {...details(item), 'tipoConteudo': item['type']},
        ],
        'page': 1,
        'total_pages': 1,
      };
    }
    if (uri.path.contains('/temporadas')) return {'temporadas': []};
    return super.respond(method, uri, body);
  }
}

void main() {
  testWidgets('appearance previews in both themes', (tester) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    for (final dark in [false, true]) {
      GoogleFonts.config.allowRuntimeFetching = false;
      final previousHttp = HttpOverrides.current;
      final backend = _PreviewBackend();
      backend.favorites.add({
        'filmeSerieId': int.parse(backend.catalog.first['id']!),
        'tipoConteudo': backend.catalog.first['type'],
      });
      HttpOverrides.global = backend;
      addTearDown(() => HttpOverrides.global = previousHttp);
      ApiService.token = 'test-token';
      ApiService.userName = 'Victor';
      ApiService.userEmail = 'victor@teste.com';
      ApiService.savedContents = [];

      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = (await tester.runAsync(() => boundary.toImage()))!;
        final data = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        await tester.runAsync(() async {
          await Directory('build/theme-preview').create(recursive: true);
          await File(
            'build/theme-preview/${dark ? "dark" : "light"}-$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
        });
        image.dispose();
      }

      Widget app(Widget home) => RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: (dark ? AppTheme.dark : AppTheme.light).copyWith(
            textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme,
          ),
          home: home,
        ),
      );
      await tester.pumpWidget(app(const LoginPage()));
      await capture('login');
      await tester.pumpWidget(
        app(
          Scaffold(
            body: const ProfilePage(isActive: false),
            bottomNavigationBar: FloatingNavigationBar(
              index: 2,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await capture('profile');
      await tester.tap(find.text('Preferências de conteúdo'));
      await capture('preferences-genres');
      await tester.tap(find.text('Drama'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await capture('preferences-titles');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(const ProfilePage(isActive: false)));
      final context = tester.element(find.byType(ProfilePage));
      showTvScoreConfirmation(
        context,
        title: 'Remover avaliação?',
        description: 'Essa ação remove sua avaliação.',
        confirmLabel: 'Remover',
        destructive: true,
      );
      await capture('dialog');
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      showSearchFilters(
        context,
        current: const SearchFilters(),
        genres: Future.value([]),
        onRetryGenres: () async => [],
      );
      await capture('sheet');
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      // Ahem test glyphs are wider than Work Sans in carousel headings.
      await tester.binding.setSurfaceSize(const Size(600, 932));
      await tester.pumpWidget(app(const Scaffold(body: HomePage())));
      await capture('home');
      await tester.pumpWidget(app(FavoritesPage(onExplore: () {})));
      await capture('favorites');
      await tester.pumpWidget(app(const SearchPage()));
      await capture('search');
      await tester.pumpWidget(
        app(
          DetailsPage(content: Map<String, String>.from(backend.catalog.first)),
        ),
      );
      await capture('details');
      await tester.scrollUntilVisible(
        find.text('Sua avaliação'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await capture('review');
      await tester.pumpWidget(
        app(
          DetailsPage(
            key: const ValueKey('series'),
            content: Map<String, String>.from(backend.catalog.first)
              ..['type'] = 'TV',
          ),
        ),
      );
      await capture('series-details');
      await tester.pumpWidget(const SizedBox());
    }
  });
}
