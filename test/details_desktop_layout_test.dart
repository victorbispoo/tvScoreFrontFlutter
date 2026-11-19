import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_breakpoints.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/details_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_header.dart';
import 'package:tv_score_front_flutter/widgets/content_poster.dart';
import 'package:tv_score_front_flutter/widgets/episode_panel.dart';
import 'package:tv_score_front_flutter/widgets/episode_ratings_grid.dart';
import 'package:tv_score_front_flutter/widgets/guest_account_prompt.dart';
import 'package:tv_score_front_flutter/widgets/season_selector.dart';

import 'support/backend_http.dart';

class _EpisodesBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/episodios/painel')) {
      requests.add('$method ${uri.path}');
      return {
        'temporadas': [
          for (final season in [1, 2])
            {
              'season_number': season,
              'episodes': [
                for (var episode = 1; episode <= 18; episode++)
                  {
                    'episode_number': episode,
                    'vote_count': episode == 1 ? 0 : 10,
                    'vote_average': 8.5,
                  },
              ],
            },
        ],
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  var seriesId = 98100;
  for (final brightness in Brightness.values) {
    for (final authenticated in [false, true]) {
      testWidgets(
        'episódios responsivos em $brightness, sessão=$authenticated',
        (tester) async {
          final id = seriesId++;
          final previous = HttpOverrides.current;
          final previousToken = ApiService.token;
          final backend = _EpisodesBackend();
          HttpOverrides.global = backend;
          ApiService.token = authenticated ? 'layout-$id' : null;
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 1000);
          addTearDown(() {
            HttpOverrides.global = previous;
            ApiService.token = previousToken;
            tester.view.reset();
          });
          await tester.pumpWidget(
            MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: DetailsPage(
                content: {
                  'id': '$id',
                  'type': 'TV',
                  'title': 'Uma série',
                  'score': '8.5',
                  'overview': 'Sinopse da série.',
                  'ondeAssistir': '{}',
                  'backdrop_path': 'https://example.com/backdrop.jpg',
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          final selector = tester.widget<SeasonSelector>(
            find.byType(SeasonSelector),
          );
          selector.onChanged(2);
          await tester.pumpAndSettle();
          for (final width in [390.0, 768.0, 1024.0, 1366.0, 1920.0, 390.0]) {
            tester.view.physicalSize = Size(width, 1000);
            await tester.pumpAndSettle();
            final panel = find.byType(EpisodePanel);
            expect(panel, findsOneWidget);
            final inHeader = find.descendant(
              of: find.byType(ContentHeader),
              matching: panel,
            );
            final panelRect = tester.getRect(panel);
            final poster = tester.getRect(find.byType(ContentPoster));
            final desktop = AppBreakpoints.supportsWidePages && width >= 1024;
            if (desktop) {
              expect(inHeader, findsOneWidget);
              expect(panelRect.left, greaterThan(poster.right));
              final synopsis = tester.getRect(find.text('Sinopse da série.'));
              expect(panelRect.top - synopsis.bottom, closeTo(24, .1));
            } else {
              expect(inHeader, findsNothing);
              expect(
                panelRect.top,
                greaterThanOrEqualTo(
                  tester.getRect(find.byType(ContentHeader)).bottom,
                ),
              );
            }
            expect(
              tester.widget<SeasonSelector>(find.byType(SeasonSelector)).value,
              2,
            );
            expect(find.text('Sem nota'), findsOneWidget);
            expect(find.text('E1'), findsOneWidget);
            final gridFinder = find.descendant(
              of: find.byType(EpisodeRatingsGrid),
              matching: find.byType(GridView),
            );
            final grid = tester.widget<GridView>(gridFinder);
            final delegate =
                grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
            final expected = ((tester.getSize(gridFinder).width + 8) / 68)
                .floor()
                .clamp(1, desktop ? 16 : 8);
            expect(delegate.crossAxisCount, expected);
            expect(tester.takeException(), isNull);
          }
        },
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.windows,
        }),
      );
    }

    testWidgets(
      'cards do Perfil visitante em $brightness',
      (tester) async {
        final previousToken = ApiService.token;
        ApiService.token = null;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          ApiService.token = previousToken;
          tester.view.reset();
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.dark
                : AppTheme.light,
            home: const Scaffold(body: ProfilePage()),
          ),
        );
        for (final width in [320.0, 390.0, 768.0, 1024.0, 1366.0, 1920.0]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpAndSettle();
          final account = tester.getRect(
            find
                .ancestor(
                  of: find.byType(GuestAccountPrompt),
                  matching: find.byType(Material),
                )
                .first,
          );
          final appearance = tester.getRect(
            find
                .ancestor(
                  of: find.text('Aparência'),
                  matching: find.byType(Material),
                )
                .first,
          );
          if (AppBreakpoints.supportsWidePages && width >= 1024) {
            expect(find.byType(TableCell), findsNWidgets(2));
            expect(appearance.left, greaterThan(account.right));
            expect(appearance.top, closeTo(account.top, .1));
            expect(appearance.height, closeTo(account.height, .1));
          } else {
            expect(find.byType(TableCell), findsNothing);
            expect(appearance.top, greaterThan(account.bottom));
          }
          for (final label in [
            'Claro',
            'Escuro',
            'Sistema',
            'Entrar',
            'Criar conta',
          ]) {
            expect(find.text(label), findsOneWidget);
          }
          expect(find.text('Editar perfil'), findsNothing);
          expect(tester.takeException(), isNull);
        }
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.windows,
      }),
    );
  }
}
