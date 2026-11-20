import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/genre_preferences.dart';
import 'package:tv_score_front_flutter/widgets/profile_photo_crop_page.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import 'genre_preferences_test.dart' show PreferencesBackend;
import 'profile_photo_test.dart' as support;

class _PhotoBackend extends PreferencesBackend {
  int photoStatus = 200;

  @override
  int responseStatus(String method, Uri uri) => uri.path.endsWith('/foto')
      ? photoStatus
      : super.responseStatus(method, uri);

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/foto')) {
      expect(method, 'PUT');
      expect(ApiService.token, 'test-token');
      expect(requests, contains('POST /api/auth/login'));
      expect(body, contains('name="arquivo"'));
      expect(body, contains('image/jpeg'));
      requests.add('PUT /usuarios/eu/foto');
      return {'fotoUrl': 'https://example.com/registered.jpg'};
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  setUp(() {
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  late _PhotoBackend backend;
  setUp(() {
    backend = _PhotoBackend();
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    final previousGallery = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = support.Gallery()
      ..file = XFile.fromData(
        img.encodePng(img.Image(width: 600, height: 800)),
        name: 'photo.png',
      );
    addTearDown(() => ImagePickerPlatform.instance = previousGallery);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    ApiService.token = null;
    ApiService.userPhotoUrl.value = null;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        onGenerateRoute: AppRoutes.generate,
        home: const RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester) async {
    await tester.ensureVisible(find.byTooltip('Escolher foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Escolher foto'));
    await support.waitForCrop(tester);
  }

  Future<void> savePhoto(WidgetTester tester) async {
    await pick(tester);
    await tester.tap(find.text('Salvar foto'));
    await support.finishCrop(tester);
  }

  Future<void> submit(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'ana@teste.com');
    await tester.enterText(fields.at(2), 'senha123');
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'recorte fica local e cancelamento preserva foto; upload só ocorre após cadastro e login',
    (tester) async {
      await open(tester);
      await savePhoto(tester);
      final bytes = tester
          .widget<UserAvatar>(find.byType(UserAvatar))
          .imageBytes!;
      final decoded = img.decodeJpg(bytes)!;
      expect(decoded.width, lessThanOrEqualTo(512));
      expect(decoded.width, decoded.height);
      expect(backend.requests, isEmpty);
      await pick(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<UserAvatar>(find.byType(UserAvatar)).imageBytes,
        bytes,
      );
      await submit(tester);
      expect(
        backend.requests.where(
          (item) => item.contains('auth/') || item == 'PUT /usuarios/eu/foto',
        ),
        [
          'POST /api/auth/cadastrar',
          'POST /api/auth/login',
          'PUT /usuarios/eu/foto',
        ],
      );
      expect(
        ApiService.userPhotoUrl.value,
        'https://example.com/registered.jpg',
      );
      expect(find.byType(ContentPreferencesDialog), findsOneWidget);
      expect(find.byType(ProfilePhotoCropPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('remover a foto local evita o upload ao cadastrar', (
    tester,
  ) async {
    await open(tester);
    await savePhoto(tester);
    await tester.ensureVisible(find.text('Remover foto'));
    await tester.tap(find.text('Remover foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<UserAvatar>(find.byType(UserAvatar)).imageBytes,
      isNull,
    );
    await submit(tester);
    expect(backend.requests.where((item) => item.endsWith('/foto')), isEmpty);
    expect(find.byType(ContentPreferencesDialog), findsOneWidget);
  });

  for (final retry in [false, true]) {
    testWidgets(
      'falha da foto preserva conta e permite continuar ou tentar novamente, retry=$retry',
      (tester) async {
        await open(tester);
        await savePhoto(tester);
        backend.photoStatus = 503;
        await submit(tester);
        expect(find.text('Conta criada'), findsOneWidget);
        expect(find.byType(ContentPreferencesDialog), findsNothing);
        expect(ApiService.token, 'test-token');
        if (retry) backend.photoStatus = 200;
        await tester.tap(
          find.text(retry ? 'Tentar novamente' : 'Continuar sem foto'),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ContentPreferencesDialog), findsOneWidget);
        expect(
          backend.requests.where((item) => item.endsWith('/auth/cadastrar')),
          hasLength(1),
        );
        expect(
          backend.requests.where((item) => item.endsWith('/auth/login')),
          hasLength(1),
        );
        expect(
          backend.requests.where((item) => item == 'PUT /usuarios/eu/foto'),
          hasLength(retry ? 2 : 1),
        );
        expect(
          ApiService.userPhotoUrl.value,
          retry ? 'https://example.com/registered.jpg' : isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
