import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/review_form.dart';

import 'support/backend_http.dart';

void main() {
  for (final token in <String?>[null, '']) {
    test(
      'sem token ($token), serviços pessoais não enviam requisições',
      () async {
        final previousToken = ApiService.token;
        ApiService.token = token;
        addTearDown(() => ApiService.token = previousToken);
        final api = ApiService();
        var requests = 0;
        api.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests++;
              handler.resolve(Response(requestOptions: options, data: {}));
            },
          ),
        );

        for (final request in <Future<dynamic> Function()>[
          api.getFavorites,
          api.getPreferredGenres,
          api.getPreferredContents,
          api.loadProfilePhoto,
        ]) {
          await expectLater(request(), throwsStateError);
        }
        expect(requests, 0);
      },
    );
  }

  testWidgets('visitante abre a Home, pesquisa e vê detalhes públicos', (
    tester,
  ) async {
    final backend = BackendHttp();
    final previous = HttpOverrides.current;
    final previousToken = ApiService.token;
    HttpOverrides.global = backend;
    ApiService.token = null;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1600);
    addTearDown(() {
      HttpOverrides.global = previous;
      ApiService.token = previousToken;
      tester.view.reset();
    });

    await tester.pumpWidget(const TvScoreApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Em alta'), findsOneWidget);
    expect(find.text('Mais bem avaliados'), findsOneWidget);
    expect(find.text('Para você'), findsNothing);

    final navigation = find.byType(FloatingNavigationBar);
    for (final label in ['Favoritos', 'Perfil']) {
      await tester.tap(
        find.descendant(of: navigation, matching: find.text(label)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(label == 'Favoritos' ? FavoritesPage : ProfilePage),
        findsOneWidget,
      );
    }
    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Início')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'avatar');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avatar: O Caminho da Água'));
    await tester.pumpAndSettle();
    expect(find.byType(DetailsPage), findsOneWidget);
    expect(find.text('Avatar: O Caminho da Água'), findsOneWidget);
    expect(find.text('TVScore: sem avaliações'), findsOneWidget);
    expect(find.byType(ReviewForm), findsNothing);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton &&
                  widget.tooltip == 'Adicionar aos favoritos',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(backend.requests, contains('GET /filmes/pesquisar'));
    expect(
      backend.requests.any((request) => request.endsWith('/resumo')),
      isTrue,
    );
    expect(
      backend.requests.where(
        (request) => !RegExp(
          r'^GET /(?:(?:filmes|series|conteudos)/|avaliacoes/conteudo/\d+/resumo$|avaliacoes/filme/\d+/paginadas$)',
        ).hasMatch(request),
      ),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
