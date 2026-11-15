import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/community_review_card.dart';
import 'package:tv_score_front_flutter/widgets/community_reviews_sheet.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import 'support/backend_http.dart';

class _Backend extends BackendHttp {
  final pages = <Uri>[];
  bool failNext = false;

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/paginadas')) {
      pages.add(uri);
      if (failNext) {
        failNext = false;
        throw const HttpException('Falha simulada');
      }
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  late _Backend backend;
  setUp(() {
    backend = _Backend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'test-token';
    ApiService.reviews = [];
    ApiService.savedContents = [];
  });

  void seed(int count) {
    backend.communityReviews.addAll(
      List.generate(
        count,
        (i) => {
          'id': i + 1,
          'filmeSerieId': 123,
          'tipoConteudo': 'MOVIE',
          'nomeUsuario': 'Pessoa ${i + 1}',
          'nota': 8.0,
          'comentario': i.isEven ? 'Uma resenha' : null,
          'dataCriacao': '2026-11-08T12:00:00',
        },
      ),
    );
  }

  for (final count in [0, 1, 2, 3, 4]) {
    testWidgets(
      'prévia com $count avaliações busca três e controla Ver todas',
      (tester) async {
        seed(count);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const DetailsPage(
              content: {
                'id': '123',
                'type': 'MOVIE',
                'title': 'Teste',
                'score': '8.0',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(backend.pages, hasLength(1));
        expect(backend.pages.single.queryParameters['tamanho'], '3');
        expect(backend.pages.single.queryParameters['pagina'], '0');
        expect(
          find.byType(CommunityReviewCard),
          findsNWidgets(count.clamp(0, 3)),
        );
        expect(
          find.text('Ver todas as avaliações'),
          count > 3 ? findsOneWidget : findsNothing,
        );
        if (count == 0) {
          expect(
            find.text('Ainda não há avaliações para este título.'),
            findsOneWidget,
          );
        }
        if (count > 3) {
          await tester.ensureVisible(find.text('Ver todas as avaliações'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Ver todas as avaliações'));
          await tester.pumpAndSettle();
          expect(find.byType(CommunityReviewsSheet), findsOneWidget);
          expect(backend.pages.last.queryParameters['tamanho'], '20');
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          expect(find.byType(CommunityReviewsSheet), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('sheet pagina até o fim sem duplicar requisições', (
    tester,
  ) async {
    seed(25);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    const CommunityReviewsSheet(contentId: 123, type: 'MOVIE'),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(CommunityReviewsSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Pessoa 25'),
      400,
      scrollable: scrollable,
      maxScrolls: 35,
    );
    await tester.pumpAndSettle();
    expect(backend.pages.map((uri) => uri.queryParameters['pagina']), [
      '0',
      '1',
    ]);
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(backend.pages, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet oferece nova tentativa após falha inicial', (
    tester,
  ) async {
    seed(1);
    backend.failNext = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const CommunityReviewsSheet(contentId: 123, type: 'MOVIE'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Pessoa 1'), findsOneWidget);
    expect(backend.pages.map((uri) => uri.queryParameters['pagina']), [
      '0',
      '0',
    ]);
  });

  testWidgets('card estreito expande comentário e avatar trata nome ausente', (
    tester,
  ) async {
    final comment = List.filled(
      40,
      'Comentário longo com quebra\nde linha.',
    ).join(' ');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 280,
              child: CommunityReviewCard(
                author: null,
                rating: 0,
                comment: comment,
                date: DateTime(2026, 11, 8),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('8 de nov de 2026'), findsOneWidget);
    expect(find.text('Ler mais'), findsOneWidget);
    await tester.tap(find.text('Ler mais'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(comment)).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
}
