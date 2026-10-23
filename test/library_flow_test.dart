import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/pages/search_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/movie_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const movie = {
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
    await SharedPreferencesAsync().clear();
    await ApiService().open('jose@teste.com', 'José Silva');
  });

  testWidgets('detalhes permite salvar título, dar nota e comentar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const DetailsPage(movie: movie),
      ),
    );
    final saveTitle = find.text('Adicionar aos favoritos');
    await tester.scrollUntilVisible(
      saveTitle,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveTitle);
    await tester.pumpAndSettle();
    expect(ApiService.savedMovies, hasLength(1));
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), 'Gostei da história!');
    await tester.scrollUntilVisible(
      find.text('Salvar avaliação'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar avaliação'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews.single.comment, 'Gostei da história!');
    expect(ApiService.reviews.single.rating, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avaliações abre edição e exclui somente após confirmação', (
    tester,
  ) async {
    await ApiService().saveReview(movie, 9, 'Muito bom');
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const MyReviewsPage()),
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

  testWidgets('busca encontra títulos e gêneros sem acento e abre detalhes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: SearchPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ficcao');
    await tester.pumpAndSettle();
    expect(find.text('Avatar: O Caminho da Água'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'stranger');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stranger Things'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'titulo inexistente');
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum título encontrado. Tente outro nome ou gênero.'),
      findsOneWidget,
    );
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
        theme: ThemeData.dark(),
        home: const Scaffold(body: SafeArea(child: HomePage())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Destaques'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Séries para maratonar'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Séries para maratonar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('favoritos atualiza depois de remover um título nos detalhes', (
    tester,
  ) async {
    await ApiService().toggleSaved(movie);
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const FavoritesPage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MovieCard));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Remover dos favoritos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Remover dos favoritos'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Sua lista está vazia'), findsOneWidget);
  });

  testWidgets('perfil atualiza suas contagens ao mudar de aba', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const AppShell()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('0 títulos salvos'), findsOneWidget);
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    await ApiService().toggleSaved(movie);
    await ApiService().saveReview(movie, 9, 'Bom');
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('1 títulos salvos'), findsOneWidget);
    expect(
      find.text('1 avaliações • Veja suas notas e comentários'),
      findsOneWidget,
    );
  });
}
