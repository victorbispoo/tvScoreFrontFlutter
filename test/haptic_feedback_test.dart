import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';

import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final feedback = <String>[];

  setUpAll(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  setUp(() {
    feedback.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            feedback.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('arraste vibra só ao mudar a aba candidata', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavigationBar(
              index: selected,
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Início'));
    expect(feedback, isEmpty);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Início')),
    );
    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();
    expect(feedback, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
    ]);
    await gesture.up();
    await tester.pump();
    expect(selected, 2);
    expect(feedback, hasLength(2));
  });

  testWidgets('cancelar arraste não vibra ao encaixar de volta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingNavigationBar(index: 0, onSelected: (_) {}),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Início')),
    );
    await gesture.moveBy(const Offset(260, 0));
    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();
    expect(feedback, ['HapticFeedbackType.selectionClick']);
    await gesture.cancel();
    await tester.pump();
    expect(feedback, hasLength(1));
  });

  testWidgets('nota e ações confirmadas geram feedback uma vez', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await SharedPreferencesAsync().clear();
    await ApiService().open('teste@email.com', 'Teste');
    const content = {
      'id': '123',
      'type': 'MOVIE',
      'title': 'Título de teste',
      'poster_path': '',
      'year': '2024',
      'score': '8.0',
      'genre': 'Drama',
    };
    await tester.pumpWidget(
      const MaterialApp(home: DetailsPage(content: content)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();
    expect(feedback, ['HapticFeedbackType.lightImpact']);
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    expect(feedback, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.lightImpact',
    ]);
    await tester.scrollUntilVisible(
      find.byTooltip('Aumentar nota'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Aumentar nota'));
    await tester.pumpAndSettle();
    expect(feedback.last, 'HapticFeedbackType.selectionClick');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Aumentar nota'));
      await tester.pumpAndSettle();
    }
    expect(find.byTooltip('Aumentar nota'), findsOneWidget);
    expect(
      feedback.where((value) => value == 'HapticFeedbackType.selectionClick'),
      hasLength(4),
    );
    await tester.scrollUntilVisible(
      find.text('Publicar avaliação'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar avaliação'));
    await tester.pumpAndSettle();
    expect(
      feedback.where((value) => value == 'HapticFeedbackType.lightImpact'),
      hasLength(3),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('exclusão cancelada não vibra; confirmada vibra uma vez', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await SharedPreferencesAsync().clear();
    await ApiService().open('teste@email.com', 'Teste');
    const content = {
      'id': '123',
      'type': 'MOVIE',
      'title': 'Título de teste',
      'poster_path': '',
      'year': '2024',
      'score': '8.0',
      'genre': 'Drama',
    };
    await tester.runAsync(() => ApiService().saveReview(content, 8, 'Bom'));
    await tester.pumpWidget(const MaterialApp(home: MyReviewsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(feedback, isEmpty);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(feedback, ['HapticFeedbackType.lightImpact']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro ao favoritar vibra só depois da falha', (tester) async {
    final backend = _FailingFavoritesBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    await SharedPreferencesAsync().clear();
    await ApiService().open('teste@email.com', 'Teste');
    const content = {
      'id': '123',
      'type': 'MOVIE',
      'title': 'Título de teste',
      'poster_path': '',
      'year': '2024',
      'score': '8.0',
      'genre': 'Drama',
    };
    await tester.pumpWidget(
      const MaterialApp(home: DetailsPage(content: content)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    expect(feedback, isEmpty);
    await tester.pumpAndSettle();
    expect(feedback, ['HapticFeedbackType.lightImpact']);
    expect(ApiService.savedContents, isEmpty);
  });
}

class _FailingFavoritesBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (method == 'POST' && uri.path.endsWith('/favoritos')) {
      throw StateError('Falha simulada');
    }
    return super.respond(method, uri, body);
  }
}
