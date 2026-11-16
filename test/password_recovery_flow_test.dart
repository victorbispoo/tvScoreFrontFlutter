import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/password_recovery_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/auth_text_field.dart';

import 'support/backend_http.dart';

class RecoveryBackend extends BackendHttp {
  RecoveryBackend(this.status);
  final int status;
  int calls = 0;
  @override
  int responseStatus(String method, Uri uri) => status;
  @override
  Object? respond(String method, Uri uri, String body) {
    calls++;
    expect(method, 'POST');
    if (uri.path.endsWith('/redefinicao')) {
      expect(jsonDecode(body), {
        'token': 'opaque+/=',
        'novaSenha': ' senha nova ',
      });
      return null;
    }
    expect(jsonDecode(body), {'email': 'user@example.com'});
    return {'message': 'Se houver uma conta, enviaremos instruções.'};
  }
}

void main() {
  Future<GlobalKey<NavigatorState>> launch(
    WidgetTester tester,
    int status, {
    String? initialRoute,
  }) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = RecoveryBackend(status);
    addTearDown(() => HttpOverrides.global = previous);
    ApiService.token = 'existing-session';
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: ThemeData.dark(),
        home: const LoginPage(),
        onGenerateRoute: AppRoutes.generate,
        initialRoute: initialRoute,
      ),
    );
    await tester.pumpAndSettle();
    return navigator;
  }

  testWidgets('login pre-fills email, neutral 202 and back preserve session', (
    tester,
  ) async {
    await launch(tester, 202);
    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    final forgot = find.text('Esqueceu a senha?');
    await tester.ensureVisible(forgot);
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    expect(
      tester.widget<AuthTextField>(find.byType(AuthTextField)).controller!.text,
      'user@example.com',
    );
    await tester.tap(find.text('Enviar solicitação'));
    await tester.pumpAndSettle();
    expect(
      find.text('Se houver uma conta, enviaremos instruções.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(ApiService.token, 'existing-session');
    expect(tester.takeException(), isNull);
  });

  for (final status in [204, 400]) {
    testWidgets('reset receives URL token and handles $status', (tester) async {
      final url = Uri.parse(
        'http://localhost:3000/redefinir-senha?token=opaque%2B%2F%3D',
      );
      final navigator = await launch(
        tester,
        status,
        initialRoute: AppRoutes.recoveryRouteFromUrl(url),
      );
      final page = tester.widget<PasswordRecoveryPage>(
        find.byType(PasswordRecoveryPage),
      );
      expect(page.token, 'opaque+/=');
      expect(
        ModalRoute.of(
          tester.element(find.byType(PasswordRecoveryPage)),
        )!.settings.name,
        AppRoutes.resetPassword,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), ' senha nova ');
      await tester.enterText(fields.at(1), 'different');
      final submit = find.widgetWithText(FilledButton, 'Redefinir senha');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('As senhas não coincidem.'), findsOneWidget);
      await tester.enterText(fields.at(1), ' senha nova ');
      await tester.tap(submit);
      await tester.pumpAndSettle();
      if (status == 204) {
        expect(find.byType(LoginPage), findsOneWidget);
        expect(navigator.currentState!.canPop(), isFalse);
        expect(
          find.text('Senha redefinida. Entre com sua nova senha.'),
          findsOneWidget,
        );
      } else {
        expect(find.byType(PasswordRecoveryPage), findsOneWidget);
        expect(find.textContaining('O link é inválido'), findsOneWidget);
      }
      expect(ApiService.token, 'existing-session');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing token disables reset; hash URLs are accepted', (
    tester,
  ) async {
    expect(
      AppRoutes.recoveryRouteFromUrl(
        Uri.parse('http://localhost:3000/#/redefinir-senha?token=opaque'),
      ),
      '/redefinir-senha?token=opaque',
    );
    await launch(tester, 204, initialRoute: '/redefinir-senha');
    expect(
      find.text('Link de recuperação inválido. Solicite um novo link.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('429 blocks resending and persists cooldown when reopened', (
    tester,
  ) async {
    final navigator = await launch(tester, 429);
    navigator.currentState!.pushNamed(
      AppRoutes.recovery,
      arguments: 'user@example.com',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar solicitação'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.textContaining('Tentar em'), findsOneWidget);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    navigator.currentState!.pushNamed(
      AppRoutes.recovery,
      arguments: 'user@example.com',
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect((HttpOverrides.current as RecoveryBackend).calls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
