import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'support/backend_http.dart';

class _WatchBackend extends BackendHttp {
  @override
  Map<String, dynamic> details(Map<String, String> content) => {
    ...super.details(content),
    'ondeAssistir': {
      'assinatura': [
        {'provider_id': 1, 'provider_name': 'Streaming Teste'},
      ],
    },
  };
}

Future<void> removeFavorite(WidgetTester tester, Finder button) async {
  await tester.tap(button);
  for (
    var attempt = 0;
    attempt < 50 && ApiService.savedContents.isNotEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(ApiService.savedContents, isEmpty);
}

void main() {
  late BackendHttp backend;
  TestWidgetsFlutterBinding.ensureInitialized();
  const content = {
    'id': '123',
    'type': 'MOVIE',
    'title': 'Título de teste',
    'poster_path': '',
    'year': '2024',
    'score': '8.0',
    'genre': 'Drama',
  };

  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  setUp(() async {
    final previous = HttpOverrides.current;
    backend = _WatchBackend();
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await SharedPreferencesAsync().clear();
    await ApiService().open('jose@teste.com', 'José Silva');
  });

  testWidgets('detalhes acomoda gênero e autor longos em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final author = List.filled(8, 'Autor de nome longo').join(' ');
    backend.communityReviews.add({
      'id': 77,
      'filmeSerieId': 123,
      'tipoConteudo': 'MOVIE',
      'nota': 8.5,
      'comentario': 'Comentário da comunidade',
      'nomeUsuario': author,
      'dataCriacao': '2026-11-08T12:00:00',
    });
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: DetailsPage(
          content: {
            ...content,
            'genre': 'Ficção Científica • Aventura • Mistério • Drama',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(author),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text(author), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detalhes permite salvar título, dar nota e comentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const DetailsPage(content: content),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Streaming Teste'), findsOneWidget);
    final saveTitle = find.byTooltip('Adicionar aos favoritos');
    await tester.scrollUntilVisible(
      saveTitle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveTitle);
    await tester.pumpAndSettle();
    expect(ApiService.savedContents, hasLength(1));
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Gostei da história!');
    await tester.pumpAndSettle();
    expect(
      backend.requests.where((request) => request == 'GET /filmes/123'),
      hasLength(1),
    );
    await tester.scrollUntilVisible(
      find.text('Publicar avaliação'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar avaliação'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews.single.comment, 'Gostei da história!');
    expect(ApiService.reviews.single.rating, 8);
    expect(find.text('Atualizar avaliação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avaliações abre edição e exclui somente após confirmação', (
    tester,
  ) async {
    await tester.runAsync(
      () => ApiService().saveReview(content, 9, 'Muito bom'),
    );
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const MyReviewsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Muito bom'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Muito bom',
    );
    await tester.enterText(find.byType(TextField), 'Comentário atualizado');
    await tester.scrollUntilVisible(
      find.text('Atualizar avaliação'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atualizar avaliação'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews.single.comment, 'Comentário atualizado');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews, hasLength(1));
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews, isEmpty);
    expect(find.text('Sua opinião merece uma nota'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busca consulta backend após pausa e permite limpar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const Scaffold(body: SearchPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(backend.requests, isEmpty);
    expect(find.text('Digite o nome de um filme ou série.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ava');
    await tester.pump(const Duration(milliseconds: 300));
    expect(backend.requests, isEmpty);

    await tester.enterText(find.byType(TextField), 'avatar');
    await tester.pump(const Duration(milliseconds: 399));
    expect(backend.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(backend.requests, ['GET /filmes/pesquisar']);
    expect(find.text('Avatar: O Caminho da Água'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'titulo inexistente');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum título encontrado. Tente outro nome.'),
      findsOneWidget,
    );

    expect(backend.requests, hasLength(2));

    final requestCount = backend.requests.length;
    await tester.enterText(find.byType(TextField), 'stranger');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(backend.requests, hasLength(requestCount));
    expect(find.text('Digite o nome de um filme ou série.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home apresenta carrosséis em uma tela de celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const Scaffold(body: SafeArea(child: HomePage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Para você'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mais bem avaliados'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Mais bem avaliados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favoritos atualiza depois de remover um título nos detalhes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => ApiService().toggleSaved(content));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    await tester.tap(find.byType(ContentCard));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Remover dos favoritos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await removeFavorite(tester, find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('botão sobre o pôster remove favorito sem abrir detalhes', (
    tester,
  ) async {
    await tester.runAsync(() => ApiService().toggleSaved(content));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const FavoritesPage(),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byTooltip('Remover dos favoritos');
    expect(tester.getSize(button), const Size(48, 48));
    await removeFavorite(tester, button);
    await tester.pumpAndSettle();
    expect(ApiService.savedContents, isEmpty);
    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(find.byType(DetailsPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil atualiza suas contagens ao mudar de aba', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: ThemeData.dark(),
        home: const AppShell(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNWidgets(2));
    expect(
      backend.requests.where((path) => path == 'GET /avaliacoes/minhas'),
      hasLength(1),
    );
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(
      backend.requests.where((path) => path == 'GET /avaliacoes/minhas'),
      hasLength(1),
    );
    await tester.runAsync(() async {
      await ApiService().toggleSaved(content);
      await ApiService().saveReview(content, 9, 'Bom');
    });
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('9.0'), findsOneWidget);
  });
}
