import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/app_shell.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/home_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/content_card.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';
import 'package:tv_score_front_flutter/widgets/preferred_content_picker.dart';

import 'support/backend_http.dart';
import 'support/gallery.dart';

class PreferencesBackend extends BackendHttp {
  final genres = <Map<String, String>>[
    {'codigo': 'animacao', 'nome': 'Animação'},
    {'codigo': 'comedia', 'nome': 'Comédia'},
    {'codigo': 'drama', 'nome': 'Drama'},
  ];
  List<String> selected = ['comedia'];
  List<Map<String, dynamic>> selectedContents = [];
  int genreStatus = 200;
  int contentStatus = 200;
  int preferredStatus = 200;
  String secondTitle = 'Escolha 1';

  @override
  int responseStatus(String method, Uri uri) {
    if (method == 'GET' && uri.path.endsWith('/conteudos-preferidos')) {
      return preferredStatus;
    }
    if (method == 'PUT' && uri.path.endsWith('/generos')) return genreStatus;
    if (method == 'PUT' && uri.path.endsWith('/conteudos-preferidos')) {
      return contentStatus;
    }
    return super.responseStatus(method, uri);
  }

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/auth/cadastrar') ||
        uri.path.endsWith('/auth/login')) {
      requests.add('$method ${uri.path}');
      return {
        'token': 'test-token',
        'nome': 'Ana',
        'email': 'ana@teste.com',
        'fotoUrl': null,
      };
    }
    if (uri.path.endsWith('/conteudos-preferidos/opcoes')) {
      requests.add('$method /usuarios/eu/conteudos-preferidos/opcoes');
      return {
        'page': 1,
        'total_pages': 1,
        'results': [
          for (var i = 0; i < 6; i++)
            {
              'id': i == 1 ? 550 : 550 + i,
              'tipoConteudo': i == 1 ? 'TV' : 'MOVIE',
              'title': i == 1 ? secondTitle : 'Escolha $i',
              'poster_path': '',
            },
        ],
      };
    }
    if (uri.path.endsWith('/conteudos-preferidos')) {
      requests.add('$method /usuarios/eu/conteudos-preferidos');
      if (method == 'PUT' && contentStatus == 200) {
        selectedContents = List<Map<String, dynamic>>.from(
          (jsonDecode(body) as Map)['conteudos'] as List,
        );
      }
      return {
        'conteudos': [
          for (final item in selectedContents)
            {...item, 'titulo': 'Anterior', 'posterPath': ''},
        ],
      };
    }
    if (uri.path == '/api/conteudos/generos') {
      requests.add('$method /conteudos/generos');
      return genres;
    }
    if (uri.path == '/api/usuarios/eu/generos') {
      requests.add('$method /usuarios/eu/generos');
      if (method == 'PUT' && genreStatus == 200) {
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
    final previousGallery = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = previousGallery);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final previous = HttpOverrides.current;
    backend = PreferencesBackend();
    HttpOverrides.global = backend;
    ApiService.token = 'test-token';
    addTearDown(() {
      HttpOverrides.global = previous;
      ApiService.token = null;
    });
  });

  Future<void> openFlow(WidgetTester tester, {bool editing = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ContentPreferencesDialog(isEditing: editing),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int index) async {
    final item = find.descendant(
      of: find.byType(PreferredContentPicker),
      matching: find.text('Escolha $index'),
    );
    final card = find
        .ancestor(of: item, matching: find.byType(AnimatedContainer))
        .first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preserva seleção ao redimensionar a grade de preferências',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1366, 900);
      addTearDown(tester.view.reset);
      await openFlow(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await choose(tester, 0);
      final cards = find.descendant(
        of: find.byType(PreferredContentPicker),
        matching: find.byType(ContentCard),
      );
      expect(
        tester.getTopLeft(cards.at(2)).dy,
        tester.getTopLeft(cards.first).dy,
      );
      tester.view.physicalSize = const Size(390, 800);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(cards.at(2)).dy,
        greaterThan(tester.getTopLeft(cards.first).dy),
      );
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      expect(find.text('Concluir').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: const TargetPlatformVariant({TargetPlatform.windows}),
  );

  testWidgets('cantos e margem interna do card selecionam e desmarcam', (
    tester,
  ) async {
    await openFlow(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    final card = find
        .ancestor(
          of: find.text('Escolha 0'),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getRect(card).topLeft + const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text('1 de 5 selecionados'), findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getRect(card).topRight + const Offset(-2, 2));
    await tester.pumpAndSettle();
    expect(find.text('0 de 5 selecionados'), findsOneWidget);
    expect(backend.requests.where((item) => item.startsWith('PUT')), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cards da segunda etapa alinham títulos e animam seleção sem mudar altura',
    (tester) async {
      backend.secondTitle = 'Um título bastante comprido que ocupa duas linhas';
      await openFlow(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      final picker = find.byType(PreferredContentPicker);
      final cards = find.descendant(
        of: picker,
        matching: find.byType(ContentCard),
      );
      expect(cards, findsNWidgets(6));
      final first = tester.getRect(cards.at(0));
      final second = tester.getRect(cards.at(1));
      expect(second.top, first.top);
      expect(second.height, first.height);
      final firstCard = find
          .ancestor(
            of: find.text('Escolha 0'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      await tester.ensureVisible(firstCard);
      await tester.pumpAndSettle();
      final height = tester.getSize(cards.first).height;
      await tester.tap(firstCard);
      await tester.pump();
      final containers = find.descendant(
        of: picker,
        matching: find.byType(AnimatedContainer),
      );
      expect(
        tester.widget<AnimatedContainer>(containers.first).duration,
        const Duration(milliseconds: 180),
      );
      final checks = find.descendant(
        of: picker,
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(checks.first).opacity, 1);
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.getSize(cards.first).height, height);
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      expect(backend.requests.where((item) => item.startsWith('PUT')), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('duas etapas cabem em tela estreita com teclado aberto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await openFlow(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.widgetWithText(FilledButton, 'Concluir')).dy,
      lessThanOrEqualTo(440),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'falha ao carregar seleção existente bloqueia conclusão e permite tentar novamente',
    (tester) async {
      backend.preferredStatus = 503;
      await openFlow(tester, editing: true);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        find.text('Não foi possível carregar as preferências.'),
        findsOneWidget,
      );
      backend.preferredStatus = 200;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(backend.requests.where((item) => item.startsWith('PUT')), isEmpty);
    },
  );

  testWidgets(
    'fechar após gravação parcial informa o que foi salvo e não executa rollback',
    (tester) async {
      await openFlow(tester, editing: true);
      await tester.tap(find.text('Drama'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      backend.contentStatus = 503;
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Gravação incompleta'), findsOneWidget);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
      expect(find.byType(ContentPreferencesDialog), findsNothing);
      expect(backend.selected, contains('drama'));
      expect(
        backend.requests.where((item) => item.startsWith('PUT')),
        hasLength(2),
      );
    },
  );

  testWidgets(
    'avançar, voltar, pesquisar e cancelar mantém escolhas somente locais',
    (tester) async {
      await openFlow(tester);
      await tester.tap(find.text('Drama'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await choose(tester, 0);
      await choose(tester, 1);
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.ensureVisible(find.text('Séries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Séries'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Avatar');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar aos gêneros'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Avatar',
      );
      await tester.tap(find.text('Escolher depois'));
      await tester.pumpAndSettle();
      expect(backend.selected, ['comedia']);
      expect(backend.selectedContents, isEmpty);
      expect(backend.requests.where((item) => item.startsWith('PUT')), isEmpty);
    },
  );

  testWidgets(
    'limita cinco conteúdos, preserva ID com tipos diferentes e evita envio duplicado',
    (tester) async {
      await openFlow(tester);
      await tester.tap(find.text('Drama'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await choose(tester, i);
      }
      expect(find.text('5 de 5 selecionados'), findsOneWidget);
      expect(
        backend.requests.where((item) => item.endsWith('/opcoes')),
        hasLength(1),
      );
      backend.responseDelay = const Duration(seconds: 1);
      backend.delayedPaths.add('/usuarios/eu/conteudos-preferidos');
      await tester.tap(find.text('Concluir'));
      await tester.tap(find.text('Concluir'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(backend.selected, ['drama']);
      expect(backend.selectedContents, hasLength(5));
      expect(
        backend.selectedContents,
        containsAll([
          {'id': 550, 'tipoConteudo': 'MOVIE'},
          {'id': 550, 'tipoConteudo': 'TV'},
        ]),
      );
      expect(backend.requests.where((item) => item.startsWith('PUT')), [
        'PUT /usuarios/eu/generos',
        'PUT /usuarios/eu/conteudos-preferidos',
      ]);
    },
  );

  for (final failure in ['genres', 'contents']) {
    testWidgets(
      'falha em $failure não informa sucesso e permite concluir novamente',
      (tester) async {
        await openFlow(tester);
        await tester.tap(find.text('Drama'));
        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        await choose(tester, 0);
        final revision = ApiService.contentPreferencesRevision.value;
        if (failure == 'genres') {
          backend.genreStatus = 503;
        } else {
          backend.contentStatus = 503;
        }
        await tester.tap(find.text('Concluir'));
        await tester.pumpAndSettle();
        expect(find.byType(ContentPreferencesDialog), findsOneWidget);
        expect(ApiService.contentPreferencesRevision.value, revision);
        if (failure == 'genres') {
          expect(
            backend.requests.where(
              (item) => item == 'PUT /usuarios/eu/conteudos-preferidos',
            ),
            isEmpty,
          );
          expect(
            find.textContaining('Não foi possível confirmar os gêneros.'),
            findsOneWidget,
          );
        } else {
          expect(
            find.textContaining('Os gêneros foram salvos.'),
            findsOneWidget,
          );
          expect(backend.selected, ['drama']);
          expect(backend.selectedContents, isEmpty);
        }
        backend.genreStatus = 200;
        backend.contentStatus = 200;
        await tester.tap(find.text('Concluir'));
        await tester.pumpAndSettle();
        expect(find.byType(ContentPreferencesDialog), findsNothing);
        expect(ApiService.contentPreferencesRevision.value, revision + 1);
        if (failure == 'contents') {
          expect(
            backend.requests.where(
              (item) => item == 'PUT /usuarios/eu/generos',
            ),
            hasLength(1),
          );
        }
      },
    );
  }

  testWidgets(
    'edição carrega conteúdos existentes e cancelamento da etapa dois não grava',
    (tester) async {
      backend.selectedContents = [
        {'id': 550, 'tipoConteudo': 'TV'},
      ];
      await openFlow(tester, editing: true);
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Anterior (Série)'), findsOneWidget);
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      await choose(tester, 0);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(backend.selectedContents, [
        {'id': 550, 'tipoConteudo': 'TV'},
      ]);
      expect(backend.requests.where((item) => item.startsWith('PUT')), isEmpty);
    },
  );

  for (final skip in [false, true]) {
    testWidgets(
      'cadastro apresenta duas etapas ou permite pular todo o fluxo, skip=$skip',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generate,
            theme: ThemeData.dark(),
            home: const RegisterPage(),
          ),
        );
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Ana');
        await tester.enterText(fields.at(1), 'ana@teste.com');
        await tester.enterText(fields.at(2), 'senha123');
        await tester.ensureVisible(find.text('Cadastrar'));
        await tester.tap(find.text('Cadastrar'));
        await tester.pumpAndSettle();
        expect(find.text('Etapa 1 de 2'), findsOneWidget);
        if (skip) {
          await tester.tap(find.text('Escolher depois'));
        } else {
          await tester.tap(find.text('Drama'));
          await tester.tap(find.text('Continuar'));
          await tester.pumpAndSettle();
          expect(find.text('Etapa 2 de 2'), findsOneWidget);
          expect(find.byType(HomePage), findsNothing);
          expect(
            backend.requests.where((item) => item.startsWith('PUT')),
            isEmpty,
          );
          await choose(tester, 1);
          await tester.tap(find.text('Concluir'));
        }
        await tester.pumpAndSettle();
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(HomePage), findsOneWidget);
        expect(
          backend.requests.where((item) => item.startsWith('PUT')),
          hasLength(skip ? 0 : 2),
        );
        if (!skip) expect(backend.selected, ['drama']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Perfil atualiza Home preservada sem reconstruir navegação e dados independentes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: ThemeData.dark(), home: const AppShell()),
      );
      await tester.pumpAndSettle();
      final home = tester.state(find.byType(HomePage));
      final shell = tester.state(find.byType(AppShell));
      final genreRequests = backend.requests
          .where((item) => item == 'GET /usuarios/eu/generos')
          .length;
      final independent = backend.requests
          .where(
            (item) =>
                item.contains('em-alta') ||
                item.contains('por-nota') ||
                item == 'GET /conteudos/generos',
          )
          .toList();
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();
      final favorites = tester.state(find.byType(FavoritesPage));
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preferências de conteúdo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drama'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FloatingNavigationBar>(find.byType(FloatingNavigationBar))
            .index,
        2,
      );
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(HomePage)), same(home));
      expect(tester.state(find.byType(AppShell)), same(shell));
      expect(
        backend.requests
            .where((item) => item == 'GET /usuarios/eu/generos')
            .length,
        genreRequests + 2,
      );
      expect(
        backend.requests.where(
          (item) =>
              item.contains('em-alta') ||
              item.contains('por-nota') ||
              item == 'GET /conteudos/generos',
        ),
        [...independent, 'GET /conteudos/generos'],
      );
      expect(backend.selected, contains('drama'));
      await tester.tap(find.text('Favoritos'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(FavoritesPage)), same(favorites));
      expect(tester.takeException(), isNull);
    },
  );

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
      await tester.tap(find.text('Preferências de conteúdo'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 selecionados'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);

      await tester.tap(find.text('Animação'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(
        backend.requests.where((request) => request.startsWith('PUT')),
        isEmpty,
      );
      await tester.tap(find.text('Concluir'));
      await tester.pumpAndSettle();
      expect(find.byType(ContentPreferencesDialog), findsNothing);
      expect(backend.selected, unorderedEquals(['comedia', 'animacao']));

      await tester.tap(find.text('Preferências de conteúdo'));
      await tester.pumpAndSettle();
      expect(find.text('2 de 5 selecionados'), findsOneWidget);
      await tester.tap(find.text('Animação'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(backend.selected, unorderedEquals(['comedia', 'animacao']));
      expect(
        backend.requests.where((request) => request.startsWith('PUT')),
        hasLength(2),
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
                  builder: (_) => const ContentPreferencesDialog(),
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
      expect(find.byType(ContentPreferencesDialog), findsNothing);
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
                builder: (_) => const ContentPreferencesDialog(),
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
