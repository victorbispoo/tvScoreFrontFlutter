import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/community_review_card.dart';
import 'package:tv_score_front_flutter/widgets/community_reviews_sheet.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';
import 'package:tv_score_front_flutter/widgets/review_form.dart';
import 'package:tv_score_front_flutter/widgets/skeleton_loading.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import 'genre_preferences_test.dart' show PreferencesBackend;
import 'support/gallery.dart';

const _content = <String, String>{
  'id': '123',
  'type': 'MOVIE',
  'title': 'Conteúdo de origem',
  'score': '8.0',
  'overview': 'Sinopse original.',
  'ondeAssistir': '{}',
  'backdrop_path': 'https://example.com/backdrop.jpg',
};

class _PublicBackend extends PreferencesBackend {
  int communityStatus = 200;
  int loginStatus = 200;

  @override
  int responseStatus(String method, Uri uri) {
    if (uri.path.endsWith('/auth/login')) return loginStatus;
    if (uri.path.contains('/avaliacoes/filme/')) return communityStatus;
    return super.responseStatus(method, uri);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PublicBackend backend;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ApiService().logout();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    backend = _PublicBackend();
    final previous = HttpOverrides.current;
    final previousGallery = ImagePickerPlatform.instance;
    HttpOverrides.global = backend;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() {
      HttpOverrides.global = previous;
      ImagePickerPlatform.instance = previousGallery;
      ApiService.token = null;
    });
  });

  void seed(int count) {
    backend.communityReviews.addAll(
      List.generate(
        count,
        (i) => {
          'id': i + 1,
          'filmeSerieId': 123,
          'tipoConteudo': 'MOVIE',
          'nomeUsuario': 'Pessoa pública ${i + 1}',
          'nota': 8.5,
          'fotoUsuarioUrl': i == 0
              ? 'https://example.com/public-photo.jpg'
              : null,
          'comentario': i == 0 ? 'Comentário público' : '',
          'dataCriacao': '2026-11-19T12:00:00',
        },
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  AppRoutes.openDetails(context, content: _content),
              child: const Text('Abrir origem'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir origem'));
    await tester.pumpAndSettle();
  }

  test(
    'leitura pública não envia JWT, inclusive com header antigo no Dio',
    () async {
      final api = ApiService();
      api.dio.options.headers['Authorization'] = 'Bearer antigo';
      final requests = <RequestOptions>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            handler.resolve(
              Response(
                requestOptions: options,
                data: options.path.endsWith('/paginadas')
                    ? {'content': [], 'totalPages': 0, 'totalElements': 0}
                    : [],
              ),
            );
          },
        ),
      );
      await api.getContentReviewsPage(123, 'MOVIE');
      await api.getContentReviews(123, 'MOVIE');
      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(request.headers['Authorization'], isNull);
        expect(request.queryParameters['tipoConteudo'], 'MOVIE');
      }
    },
  );

  for (final status in [401, 403]) {
    testWidgets('listagem protegida $status preserva o resumo público', (
      tester,
    ) async {
      seed(1);
      backend.communityStatus = status;
      await open(tester);
      expect(find.text('TVScore:\u00a08.5/10'), findsOneWidget);
      expect(find.text(CommunityReviewsRestricted.message), findsOneWidget);
      expect(
        find.text('Ainda não há avaliações para este título.'),
        findsNothing,
      );
      expect(find.byType(LoginPage), findsNothing);
      expect(
        backend.requests.where(
          (r) => r.contains('/minhas') || r.startsWith('POST'),
        ),
        isEmpty,
      );
      backend.communityStatus = 200;
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Pessoa pública 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('visitante vê nome, foto, nota, comentário e paginação pública', (
    tester,
  ) async {
    seed(4);
    await open(tester);
    expect(find.byType(CommunityReviewCard), findsNWidgets(3));
    expect(find.text('Comentário público'), findsOneWidget);
    expect(
      tester.widget<UserAvatar>(find.byType(UserAvatar).first).imageUrl,
      'https://example.com/public-photo.jpg',
    );
    expect(find.byType(ReviewForm), findsNothing);
    await tester.ensureVisible(find.text('Ver todas as avaliações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todas as avaliações'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityReviewsSheet), findsOneWidget);
    final fourth = find.descendant(
      of: find.byType(CommunityReviewsSheet),
      matching: find.text('Pessoa pública 4'),
    );
    await tester.scrollUntilVisible(
      fourth,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CommunityReviewsSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(fourth, findsOneWidget);
    expect(ApiService.hasSession, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comunidade tem carregamento, vazio, erro e nova tentativa', (
    tester,
  ) async {
    backend.responseDelay = const Duration(seconds: 1);
    backend.delayedPaths.add('/avaliacoes/filme/123/paginadas');
    await tester.pumpWidget(
      const MaterialApp(home: DetailsPage(content: _content)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SkeletonShimmer), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text('Ainda não há avaliações para este título.'),
      findsOneWidget,
    );

    backend.communityStatus = 500;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(home: DetailsPage(content: _content)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar as avaliações.'),
      findsOneWidget,
    );
    backend.communityStatus = 200;
    seed(1);
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Comentário público'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final registration in [false, true]) {
    testWidgets(
      'autenticação retorna ao conteúdo, cadastro=$registration, sem publicar',
      (tester) async {
        await open(tester);
        final original = tester.state(find.byType(DetailsPage));
        final button = find.text('Entrar para avaliar');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        final scrollable = find
            .descendant(
              of: find.byType(DetailsPage),
              matching: find.byType(Scrollable),
            )
            .first;
        final originalOffset = tester
            .state<ScrollableState>(scrollable)
            .position
            .pixels;
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        if (registration) {
          await tester.ensureVisible(find.text('Cadastre-se'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Cadastre-se'));
          await tester.pumpAndSettle();
          expect(find.byType(RegisterPage), findsOneWidget);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Ana');
          await tester.enterText(fields.at(1), 'ana@teste.com');
          await tester.enterText(fields.at(2), 'senha-teste');
          await tester.ensureVisible(find.text('Cadastrar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Cadastrar'));
          await tester.pumpAndSettle();
          expect(find.byType(ContentPreferencesDialog), findsOneWidget);
          await tester.tap(find.text('Escolher depois'));
          await tester.pumpAndSettle();
        } else {
          backend.loginStatus = 401;
          await tester.enterText(
            find.byType(TextFormField).first,
            'ana@teste.com',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'senha-teste',
          );
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Entrar'),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
          await tester.pumpAndSettle();
          expect(find.byType(LoginPage), findsOneWidget);
          backend.loginStatus = 200;
          await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
          await tester.pumpAndSettle();
        }
        expect(tester.state(find.byType(DetailsPage)), same(original));
        expect(
          tester.widget<DetailsPage>(find.byType(DetailsPage)).content,
          same(_content),
        );
        expect(
          tester.state<ScrollableState>(scrollable).position.pixels,
          closeTo(originalOffset, 1),
        );
        expect(find.byType(ReviewForm), findsOneWidget);
        expect(ApiService.hasSession, isTrue);
        expect(find.byType(LoginPage), findsNothing);
        expect(find.byType(RegisterPage), findsNothing);
        expect(
          backend.requests.where(
            (r) => r == 'POST /avaliacoes' || r.startsWith('PUT /avaliacoes'),
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('cancelar login mantém conteúdo e estado visitante', (
    tester,
  ) async {
    await open(tester);
    final original = tester.state(find.byType(DetailsPage));
    await tester.ensureVisible(find.text('Entrar para avaliar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar para avaliar'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(LoginPage))).pop();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(DetailsPage)), same(original));
    expect(find.byType(ReviewForm), findsNothing);
    expect(ApiService.hasSession, isFalse);
    expect(tester.takeException(), isNull);
  });
}
