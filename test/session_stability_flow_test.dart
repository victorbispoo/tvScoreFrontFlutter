import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_carousel.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';
import 'package:tv_score_front_flutter/widgets/review_form.dart';

import 'auth_session_test.dart' show tokenWithExpiration;
import 'genre_preferences_test.dart' show PreferencesBackend;

const _content = <String, String>{
  'id': '123',
  'type': 'MOVIE',
  'title': 'Origem pública',
  'score': '8',
  'ondeAssistir': '{}',
  'backdrop_path': 'https://example.com/backdrop.jpg',
};

void main() {
  late PreferencesBackend backend;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().logout();
    backend = PreferencesBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() async {
      HttpOverrides.global = previous;
      await ApiService().logout();
    });
    await ApiService().open('a@teste.com', 'Conta A');
    ApiService.token = 'conta-a';
  });

  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingNavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sair do Perfil abre Home pública sem login e sem histórico privado',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const TvScoreApp());
      await tester.pumpAndSettle();
      await select(tester, 'Perfil');
      await tester.ensureVisible(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair da conta'));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(ApiService.token, isNull);
      expect(ApiService.userEmail, isEmpty);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
      expect(
        Navigator.of(tester.element(find.byType(HomePage))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home preservada descarta preferências e recomendações da conta anterior',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pumpAndSettle();
      final home = tester.state(find.byType(HomePage));
      final personalGenre = find.byWidgetPredicate(
        (widget) =>
            widget is ContentCarousel && widget.heroSection == 'genre:comedia',
      );
      expect(personalGenre, findsOneWidget);
      await ApiService().logout();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomePage)), same(home));
      expect(personalGenre, findsNothing);
      expect(find.text('Para você'), findsNothing);
      final reads = backend.requests
          .where((r) => r == 'GET /usuarios/eu/generos')
          .length;
      backend.selected = ['drama'];
      await ApiService().open('b@teste.com', 'Conta B');
      ApiService.token = 'conta-b';
      await tester.pumpAndSettle();
      expect(personalGenre, findsNothing);
      expect(
        backend.requests.where((r) => r == 'GET /usuarios/eu/generos').length,
        reads + 1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detalhes mantêm a origem e removem rascunho privado ao trocar sessão',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generate,
          home: const DetailsPage(content: _content),
        ),
      );
      await tester.pumpAndSettle();
      final origin = tester.state(find.byType(DetailsPage));
      tester
              .widget<ReviewForm>(find.byType(ReviewForm))
              .commentController
              .text =
          'Rascunho privado A';
      await ApiService().logout();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(DetailsPage)), same(origin));
      expect(find.byType(ReviewForm), findsNothing);
      expect(find.text('Entrar para avaliar'), findsOneWidget);
      ApiService.token = 'conta-b';
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ReviewForm>(find.byType(ReviewForm))
            .commentController
            .text,
        isEmpty,
      );
      expect(backend.requests.where((r) => r == 'POST /avaliacoes'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expiração em detalhes mantém navegação pública sem abrir login',
    (tester) async {
      final expiration = DateTime.fromMillisecondsSinceEpoch(
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3) * 1000,
      );
      ApiService.token = tokenWithExpiration(
        expiration.millisecondsSinceEpoch ~/ 1000,
      );
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generate,
          home: const DetailsPage(content: _content),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReviewForm), findsOneWidget);
      expect(ApiService.hasSession, isTrue);
      // The widget clock fires the timer, but the JWT compares wall time.
      await tester.runAsync(
        () => Future<void>.delayed(expiration.difference(DateTime.now())),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(DetailsPage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ReviewForm), findsNothing);
      expect(find.text('Avaliações da comunidade'), findsOneWidget);
      expect(ApiService.hasSession, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rota Minhas avaliações não mantém dados de conta encerrada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        initialRoute: AppRoutes.myReviews,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MyReviewsPage), findsOneWidget);
    await ApiService().logout();
    await tester.pumpAndSettle();
    expect(find.byType(MyReviewsPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preferências abertas não sobrevivem à troca de conta com mesmo token',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      const ContentPreferencesDialog(isEditing: true),
                ),
                child: const Text('Preferências'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Preferências'));
      await tester.pumpAndSettle();
      expect(find.byType(ContentPreferencesDialog), findsOneWidget);
      await ApiService().logout();
      ApiService.token = 'conta-a';
      await tester.pumpAndSettle();
      expect(find.byType(ContentPreferencesDialog), findsNothing);
      expect(backend.requests.where((r) => r.startsWith('PUT')), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
