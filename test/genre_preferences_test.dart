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
}
