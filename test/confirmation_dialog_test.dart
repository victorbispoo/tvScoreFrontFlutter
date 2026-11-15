import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/pages/my_reviews_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_confirmation_dialog.dart';

import 'support/backend_http.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'confirmação neutra retorna false ao cancelar e true ao confirmar',
    (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showTvScoreConfirmation(
                    context,
                    title: 'Confirmar ação?',
                    description: 'Descrição da ação.',
                    confirmLabel: 'Confirmar',
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, false);
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Voltar e toque fora descartam sem confirmar', (tester) async {
    bool? result = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTvScoreConfirmation(
                  context,
                  title: 'Excluir avaliação?',
                  description: 'Descrição.',
                  confirmLabel: 'Excluir',
                  destructive: true,
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(result, isNull);
    result = true;
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('diálogo destrutivo é compacto e ações ficam à direita', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTvScoreConfirmation(
                context,
                title: 'Excluir avaliação',
                description:
                    'Sua avaliação de Filme será removida permanentemente.',
                emphasis: 'Filme',
                confirmLabel: 'Excluir',
                destructive: true,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final dialog = find.byType(BackdropFilter);
    expect(tester.getSize(dialog).height, lessThan(270));
    expect(
      tester.getTopRight(find.widgetWithText(FilledButton, 'Excluir')).dx,
      greaterThan(tester.getCenter(dialog).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('título longo cabe em tela pequena com texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTvScoreConfirmation(
                context,
                title: 'Excluir avaliação',
                description:
                    'Sua avaliação de ${'Título muito longo ' * 12} será removida permanentemente.',
                confirmLabel: 'Excluir',
                destructive: true,
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir avaliação'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro de rede mantém a avaliação após confirmação', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previous = HttpOverrides.current;
    HttpOverrides.global = _FailingDeleteBackend();
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
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();
    expect(ApiService.reviews, hasLength(1));
    expect(find.textContaining('Não foi possível excluir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FailingDeleteBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (method == 'DELETE' && uri.path.contains('/avaliacoes/')) {
      throw StateError('Falha simulada');
    }
    return super.respond(method, uri, body);
  }
}
