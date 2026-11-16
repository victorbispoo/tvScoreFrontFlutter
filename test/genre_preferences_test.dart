import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
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
          onGenerateRoute: AppRoutes.generate,
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
          onGenerateRoute: AppRoutes.generate,
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
        onGenerateRoute: AppRoutes.generate,
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

    for (final entry in {
      'tmdb-10759': HugeIconsSolid.adventure,
      'tmdb-12': HugeIconsSolid.compass01,
      'tmdb-28': HugeIconsSolid.sword01,
      'tmdb-10770': HugeIconsSolid.tv01,
      'tmdb-14': HugeIconsSolid.magicWand01,
      'tmdb-878': HugeIconsSolid.alien01,
      'tmdb-10752': HugeIconsSolid.shield01,
      'tmdb-36': HugeIconsSolid.book01,
      'tmdb-10762': HugeIconsSolid.baby01,
      'tmdb-10402': HugeIconsSolid.musicNote01,
      'tmdb-10763': HugeIconsSolid.globe02,
      'tmdb-10764': HugeIconsSolid.view,
      'tmdb-10749': HugeIconsSolid.favourite,
      'tmdb-10765': HugeIconsSolid.rocket01,
      'tmdb-10766': HugeIconsSolid.bubbleChat,
      'tmdb-10767': HugeIconsSolid.chat01,
      'tmdb-27': HugeIconsSolid.fire,
      'tmdb-53': HugeIconsSolid.brain,
      'tmdb-10768': HugeIconsSolid.shield01,
    }.entries) {
      expect(genreIcon(entry.key), entry.value);
      expect(find.byIcon(entry.value), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });
}
