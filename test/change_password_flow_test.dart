import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';

import 'support/backend_http.dart';
import 'support/gallery.dart';

class PasswordBackend extends BackendHttp {
  PasswordBackend(this.status);
  final int status;
  int submissions = 0;

  @override
  int responseStatus(String method, Uri uri) =>
      uri.path.endsWith('/senha') ? status : super.responseStatus(method, uri);

  @override
  Object? respond(String method, Uri uri, String body) {
    if (uri.path.endsWith('/senha')) {
      submissions++;
      expect(method, 'PUT');
      expect(jsonDecode(body), {
        'senhaAtual': ' atual ',
        'novaSenha': ' nova senha ',
      });
      return null;
    }
    return super.respond(method, uri, body);
  }
}

void main() {
  setUp(() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = previous);
  });
  for (final status in [204, 401, 403]) {
    testWidgets('troca de senha no perfil: HTTP $status', (tester) async {
      FlutterSecureStorage.setMockInitialValues({'tv_score_session': 'old'});
      ApiService.token = 'old';
      ApiService.userName = 'Victor';
      ApiService.userEmail = 'victor@test.com';
      final previous = HttpOverrides.current;
      final backend = PasswordBackend(status);
      HttpOverrides.global = backend;
      addTearDown(() => HttpOverrides.global = previous);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: ThemeData.dark(),
          onGenerateRoute: AppRoutes.generate,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const Scaffold(body: ProfilePage(isActive: false)),
                  ),
                ),
                child: const Text('Abrir perfil'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Alterar senha'));
      await tester.tap(find.text('Alterar senha'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), ' atual ');
      await tester.enterText(fields.at(1), ' nova senha ');
      await tester.enterText(fields.at(2), ' nova senha ');
      final submit = find.widgetWithText(FilledButton, 'Alterar senha');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(backend.submissions, 1);
      if (status == 403) {
        expect(find.text('Senha atual incorreta.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(ApiService.token, 'old');
      } else {
        expect(ApiService.token, isNull);
        expect(
          await const FlutterSecureStorage().read(key: 'tv_score_session'),
          isNull,
        );
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.byType(ProfilePage), findsNothing);
        expect(navigator.currentState!.canPop(), isFalse);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
