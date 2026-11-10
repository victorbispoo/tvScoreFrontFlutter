import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/controllers/login_controller.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/episode_panel.dart';
import 'package:tv_score_front_flutter/widgets/episode_ratings_grid.dart';

import 'support/backend_http.dart';

class EpisodeBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/episodios/painel')) {
      requests.add('$method ${uri.path}');
      final number = uri.path.contains('/series/2/') ? 999 : 1;
      return {
        'temporadas': [
          {
            'season_number': 1,
            'episodes': [
              {'episode_number': number, 'vote_count': 10, 'vote_average': 8.5},
            ],
          },
        ],
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'trocar a série recarrega o painel sem reaproveitar episódios anteriores',
    (tester) async {
      final previous = HttpOverrides.current;
      final backend = EpisodeBackend();
      HttpOverrides.global = backend;
      addTearDown(() => HttpOverrides.global = previous);

      Widget panel(int id) => MaterialApp(
        home: Scaffold(body: EpisodePanel(seriesId: id)),
      );
      await tester.pumpWidget(panel(1));
      await tester.pumpAndSettle();
      expect(find.text('E1'), findsOneWidget);
      await tester.pumpWidget(panel(2));
      await tester.pumpAndSettle();
      expect(find.text('E999'), findsOneWidget);
      expect(find.text('E1'), findsNothing);
      expect(backend.requests, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grid mantém numeração absoluta, sem votos e seleção de temporada',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EpisodeRatingsGrid(
                seasons: [
                  {
                    'season_number': 1,
                    'episodes': [
                      {
                        'episode_number': 229,
                        'vote_count': 0,
                        'vote_average': 0,
                      },
                    ],
                  },
                  {
                    'season_number': 2,
                    'episodes': [
                      {
                        'episode_number': 1000,
                        'vote_count': 10,
                        'vote_average': 9.8,
                      },
                    ],
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('E229'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('E1000'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Temporada 2').last);
      await tester.pumpAndSettle();
      expect(find.text('E1000'), findsOneWidget);
      expect(find.text('9.8'), findsOneWidget);
      expect(find.text('E229'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'login bloqueia envio duplicado e encerra requisição após descarte do controller',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final api = ApiService();
      final started = Completer<void>();
      final release = Completer<void>();
      var requests = 0;
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            requests++;
            started.complete();
            await release.future;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'token': ''},
              ),
            );
          },
        ),
      );
      final controller = LoginController(apiService: api);
      controller.emailController.text = 'teste@exemplo.com';
      controller.passwordController.text = 'senha-de-teste';
      final pending = controller.submit();
      await started.future;
      expect(await controller.submit(), isFalse);
      expect(requests, 1);
      controller.dispose();
      release.complete();
      expect(await pending, isFalse);
    },
  );
}
