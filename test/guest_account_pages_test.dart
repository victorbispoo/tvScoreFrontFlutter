import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/theme_controller.dart';
import 'package:tv_score_front_flutter/main.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/desktop_navigation.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/guest_account_prompt.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import 'support/backend_http.dart';
import 'support/gallery.dart';

class _AccountBackend extends BackendHttp {
  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path == '/api/auth/login') {
      requests.add('POST /auth/login');
      return {
        'token': 'new-session',
        'email': 'ana@teste.com',
        'nome': 'Ana',
        'fotoUrl': null,
      };
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  late _AccountBackend backend;

  setUp(() {
    final previousGallery = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    final previous = HttpOverrides.current;
    backend = _AccountBackend();
    HttpOverrides.global = backend;
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.token = null;
    // Even if old data remains in memory, visitors must never see it.
    ApiService.userName = 'Conta anterior';
    ApiService.userEmail = 'anterior@teste.com';
    ApiService.userPhotoUrl.value = 'https://example.com/old.jpg';
    ApiService.savedContents = [backend.catalog.first];
    final previousTheme = ThemeController.instance.value;
    addTearDown(() {
      ImagePickerPlatform.instance = previousGallery;
      HttpOverrides.global = previous;
      ApiService.token = null;
      ApiService.savedContents = [];
      ApiService.userName = '';
      ApiService.userEmail = '';
      ApiService.userPhotoUrl.value = null;
      ThemeController.instance.value = previousTheme;
    });
  });

  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const TvScoreApp());
    await tester.pumpAndSettle();
  }

  Future<void> selectTab(WidgetTester tester, String label) async {
    final navigation = find.byType(
      tester.view.physicalSize.width >= 1024
          ? DesktopNavigation
          : FloatingNavigationBar,
    );
    await tester.tap(
      find.descendant(of: navigation, matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 390.0, 1366.0]) {
    testWidgets(
      'visitante navega sem dados pessoais em $width dp',
      (tester) async {
        await open(tester, Size(width, 850));
        await selectTab(tester, 'Favoritos');
        expect(find.byType(FavoritesPage), findsOneWidget);
        expect(find.text('Seus favoritos no TVScore'), findsOneWidget);
        expect(find.text('1 título salvo'), findsNothing);
        expect(find.text(backend.catalog.first['title']!), findsNothing);
        await tester.tap(find.widgetWithText(OutlinedButton, 'Criar conta'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterPage), findsOneWidget);
        Navigator.of(tester.element(find.byType(RegisterPage))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(GuestAccountPrompt), findsOneWidget);

        await selectTab(tester, 'Perfil');
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.text('Sua conta no TVScore'), findsOneWidget);
        expect(find.byType(UserAvatar), findsNothing);
        for (final label in [
          'Conta anterior',
          'anterior@teste.com',
          'Editar perfil',
          'Preferências de conteúdo',
          'Minhas avaliações',
          'Sair da conta',
          'Suas estatísticas',
        ]) {
          expect(find.text(label), findsNothing);
        }
        expect(find.text('Aparência'), findsOneWidget);
        await tester.ensureVisible(find.text('Claro'));
        await tester.tap(find.text('Claro'));
        await tester.pumpAndSettle();
        expect(ThemeController.instance.value, ThemeMode.light);
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        Navigator.of(tester.element(find.byType(LoginPage))).pop();
        await tester.pumpAndSettle();
        expect(find.text('Sua conta no TVScore'), findsOneWidget);
        expect(
          backend.requests.where(
            (request) =>
                request.contains('/usuarios/') ||
                request.contains('/favoritos') ||
                request.contains('/avaliacoes/minhas') ||
                request.contains('/recomendacoes/'),
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.windows,
      }),
    );
  }

  testWidgets('login existente atualiza abas e a shell anterior ao voltar', (
    tester,
  ) async {
    await open(tester, const Size(390, 850));
    await selectTab(tester, 'Favoritos');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'ana@teste.com');
    await tester.enterText(find.byType(TextFormField).last, 'senha-teste');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(ApiService.hasSession, isTrue);
    expect(find.byType(LoginPage), findsNothing);
    await selectTab(tester, 'Favoritos');
    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(find.byType(GuestAccountPrompt), findsNothing);
    await selectTab(tester, 'Perfil');
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(backend.requests, contains('GET /favoritos'));
    expect(backend.requests, contains('GET /avaliacoes/minhas'));

    // Login replaces its own route; the original shell remains underneath.
    Navigator.of(tester.element(find.byType(ProfilePage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesPage), findsOneWidget);
    expect(find.text('Sua lista está vazia'), findsOneWidget);
    expect(find.byType(GuestAccountPrompt), findsNothing);
    await selectTab(tester, 'Perfil');
    expect(find.text('Ana'), findsOneWidget);

    final requestsBeforeLogout = backend.requests.length;
    await ApiService().logout();
    await tester.pumpAndSettle();
    expect(find.text('Sua conta no TVScore'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Editar perfil'), findsNothing);
    await selectTab(tester, 'Favoritos');
    expect(find.text('Seus favoritos no TVScore'), findsOneWidget);
    expect(backend.requests.length, requestsBeforeLogout);
    expect(tester.takeException(), isNull);
  });
}
