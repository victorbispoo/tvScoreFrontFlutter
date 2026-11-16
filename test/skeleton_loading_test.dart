import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/content_poster.dart';
import 'package:tv_score_front_flutter/widgets/skeleton_loading.dart';
import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('skeleton respeita movimento reduzido e telas estreitas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SkeletonCarousel(showFilters: true)),
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(SkeletonPosterCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pesquisa só mostra skeleton se a resposta demorar', (
    tester,
  ) async {
    final backend = BackendHttp()
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.add('/filmes/pesquisar');
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: Scaffold(body: SearchPage()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'avatar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 149));
    expect(find.byType(SkeletonGrid), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(SkeletonGrid), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonGrid), findsNothing);
    expect(find.text('Avatar: O Caminho da Água'), findsOneWidget);
  });

  testWidgets('Home revela Em alta enquanto gêneros ainda carregam', (
    tester,
  ) async {
    final backend = BackendHttp()
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.add('/conteudos/generos');
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = null;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: Scaffold(body: HomePage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SkeletonCarousel), findsWidgets);
    expect(find.text('Em alta'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonCarousel), findsNothing);
  });

  testWidgets('Detalhes mantém título visível enquanto comunidade carrega', (
    tester,
  ) async {
    final backend = BackendHttp()
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.addAll({
        '/avaliacoes/conteudo/123/resumo',
        '/avaliacoes/filme/123/paginadas',
      });
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: DetailsPage(
          content: {
            'id': '123',
            'type': 'MOVIE',
            'title': 'Filme disponível',
            'poster_path': '',
            'backdrop_path': '',
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Filme disponível'), findsOneWidget);
    expect(find.byType(SkeletonShimmer), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonShimmer), findsNothing);
    expect(
      find.text('Ainda não há avaliações para este título.'),
      findsOneWidget,
    );
  });

  testWidgets('imagem indisponível mantém fallback no pôster', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        home: SizedBox(
          width: 144,
          height: 216,
          child: ContentPoster(content: {'poster_path': ''}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
  });

  testWidgets('favoritos mostra skeleton apenas sem dados em memória', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().open('skeleton@teste.com', 'Teste');
    ApiService.token = 'test-token';
    final backend = BackendHttp()
      ..responseDelay = const Duration(seconds: 1)
      ..delayedPaths.add('/favoritos');
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);

    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: FavoritesPage()),
    );
    await tester.pump();
    expect(find.byType(SkeletonGrid), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonGrid), findsNothing);
    expect(find.text('Sua lista está vazia'), findsOneWidget);

    ApiService.savedContents = [
      {'id': '123', 'type': 'MOVIE', 'title': 'Salvo', 'poster_path': ''},
    ];
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(onGenerateRoute: AppRoutes.generate, home: FavoritesPage()),
    );
    await tester.pump();
    expect(find.byType(SkeletonGrid), findsNothing);
    expect(find.byType(ContentCard), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
