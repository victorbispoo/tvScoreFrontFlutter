import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';

import 'support/backend_http.dart';

class PreferencesBackend extends BackendHttp {
  final genres = <Map<String, String>>[
    {'codigo': 'animacao', 'nome': 'Animação'},
    {'codigo': 'comedia', 'nome': 'Comédia'},
    {'codigo': 'drama', 'nome': 'Drama'},
  ];
  List<String> selected = ['comedia'];

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path == '/api/conteudos/generos') {
      requests.add('$method /conteudos/generos');
      return genres;
    }
    if (uri.path == '/api/usuarios/eu/generos') {
      requests.add('$method /usuarios/eu/generos');
      if (method == 'PUT') {
        selected = List<String>.from(
          (jsonDecode(body) as Map)['generos'] as List,
        );
      }
      return {
        'generos': genres
            .where((genre) => selected.contains(genre['codigo']))
            .toList(),
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  late PreferencesBackend backend;

  setUp(() {
    final previous = HttpOverrides.current;
    backend = PreferencesBackend();
    HttpOverrides.global = backend;
    ApiService.token = 'test-token';
    addTearDown(() {
      HttpOverrides.global = previous;
      ApiService.token = null;
    });
  });

  testWidgets(
    'Perfil reabre escolhas salvas, atualiza e permite cancelar alterações',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: ProfilePage(isActive: false)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gêneros favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      expect(find.text('Salvar preferências'), findsOneWidget);

      await tester.tap(find.text('Animação'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Salvar preferências'));
      await tester.pumpAndSettle();
      expect(find.byType(GenrePreferencesDialog), findsNothing);
      expect(backend.selected, unorderedEquals(['comedia', 'animacao']));

      await tester.tap(find.text('Gêneros favoritos'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Animação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(backend.selected, unorderedEquals(['comedia', 'animacao']));
      expect(
        backend.requests.where((request) => request.startsWith('PUT')),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'seleção inicial permanece vazia e escolher depois não grava preferências',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const GenrePreferencesDialog(),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('0 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Escolher depois'));
      await tester.pumpAndSettle();
      expect(find.byType(GenrePreferencesDialog), findsNothing);
      expect(backend.requests, ['GET /conteudos/generos']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gêneros adicionais exibem ícones específicos', (tester) async {
    backend.genres.addAll([
      {'codigo': 'tmdb-10759', 'nome': 'Action & Adventure'},
      {'codigo': 'tmdb-12', 'nome': 'Aventura'},
      {'codigo': 'tmdb-28', 'nome': 'Ação'},
      {'codigo': 'tmdb-10770', 'nome': 'Cinema TV'},
      {'codigo': 'tmdb-14', 'nome': 'Fantasia'},
      {'codigo': 'tmdb-878', 'nome': 'Ficção científica'},
      {'codigo': 'tmdb-10752', 'nome': 'Guerra'},
      {'codigo': 'tmdb-36', 'nome': 'História'},
      {'codigo': 'tmdb-10762', 'nome': 'Kids'},
      {'codigo': 'tmdb-10402', 'nome': 'Música'},
      {'codigo': 'tmdb-10763', 'nome': 'News'},
      {'codigo': 'tmdb-10764', 'nome': 'Reality'},
      {'codigo': 'tmdb-10749', 'nome': 'Romance'},
      {'codigo': 'tmdb-10765', 'nome': 'Sci-Fi & Fantasy'},
      {'codigo': 'tmdb-10766', 'nome': 'Soap'},
      {'codigo': 'tmdb-10767', 'nome': 'Talk'},
      {'codigo': 'tmdb-27', 'nome': 'Terror'},
      {'codigo': 'tmdb-53', 'nome': 'Thriller'},
      {'codigo': 'tmdb-10768', 'nome': 'War & Politics'},
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const GenrePreferencesDialog(),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    for (final icon in [
      Icons.explore_outlined,
      Icons.hiking_outlined,
      Icons.sports_martial_arts_outlined,
      Icons.live_tv_outlined,
      Icons.auto_awesome_outlined,
      Icons.science_outlined,
      Icons.military_tech_outlined,
      Icons.history_edu_outlined,
      Icons.child_care_outlined,
      Icons.music_note_outlined,
      Icons.newspaper_outlined,
      Icons.visibility_outlined,
      Icons.favorite_border_rounded,
      Icons.rocket_launch_outlined,
      Icons.bubble_chart_outlined,
      Icons.forum_outlined,
      Icons.mood_bad_outlined,
      Icons.psychology_alt_outlined,
      Icons.policy_outlined,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
