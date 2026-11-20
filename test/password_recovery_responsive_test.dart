import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/password_recovery_page.dart';
import 'package:tv_score_front_flutter/widgets/auth_text_field.dart';
import 'package:tv_score_front_flutter/widgets/cinematic_poster_composition.dart';

import 'password_recovery_flow_test.dart' show RecoveryBackend;

class _OfflineBackend extends RecoveryBackend {
  _OfflineBackend() : super(202);

  @override
  Object? respond(String method, Uri uri, String body) {
    calls++;
    throw const SocketException('Simulated offline request');
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  Future<void> launch(
    WidgetTester tester,
    RecoveryBackend backend, {
    bool dark = true,
    double textScale = 1,
  }) async {
    final previous = HttpOverrides.current;
    HttpOverrides.global = backend;
    addTearDown(() => HttpOverrides.global = previous);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const PasswordRecoveryPage.request(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'recovery adapts to width, short screens and keyboard, dark=$dark',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1366, 640);
        addTearDown(tester.view.reset);
        final backend = RecoveryBackend(202);
        await launch(tester, backend, dark: dark);
        for (final width in [
          320.0,
          360.0,
          390.0,
          768.0,
          1024.0,
          1366.0,
          1920.0,
        ]) {
          tester.view.viewInsets = const FakeViewPadding();
          tester.view.physicalSize = Size(width, 640);
          await tester.pumpAndSettle();
          final form = tester.getRect(find.byType(Form));
          final artwork = tester.getRect(
            find.byType(CinematicPosterComposition),
          );
          expect(find.byType(AuthTextField), findsOneWidget);
          expect(
            find.text(
              'Informe seu e-mail para receber as instruções de recuperação.',
            ),
            findsOneWidget,
          );
          final composition = tester.widget<CinematicPosterComposition>(
            find.byType(CinematicPosterComposition),
          );
          expect(composition.compact, width < 1024);
          expect(composition.collageAsset, 'lib/assets/colagemLogin.jpg');
          if (width >= 1024) {
            expect(artwork.right, lessThan(form.left));
            final card = find
                .ancestor(
                  of: find.byType(Form),
                  matching: find.byType(ClipRRect),
                )
                .first;
            expect(
              tester.getSize(card).width,
              closeTo((width * .45 - 64).clamp(0, 420), .01),
            );
            expect(tester.getSize(card).height, lessThan(640));
          } else {
            expect(artwork.bottom, lessThan(form.top));
            expect(artwork.height, inInclusiveRange(120, 170));
          }
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Enviar solicitação'));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.text('Enviar solicitação')).bottom,
            lessThanOrEqualTo(360),
          );
          expect(tester.takeException(), isNull);
        }
        expect(backend.calls, 0);
      },
      variant: const TargetPlatformVariant({TargetPlatform.windows}),
    );
  }

  testWidgets(
    'empty and invalid emails remain visible without making requests',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      final backend = RecoveryBackend(202);
      await launch(tester, backend);
      for (final email in ['', 'invalid-email']) {
        await tester.enterText(find.byType(TextFormField), email);
        await tester.ensureVisible(find.text('Enviar solicitação'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enviar solicitação'));
        await tester.pumpAndSettle();
        expect(find.text('Informe um e-mail válido.'), findsOneWidget);
        expect(backend.calls, 0);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final state in ['success', 'server', 'offline']) {
    testWidgets(
      'loading and $state feedback fit narrow screens with large text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.reset);
        final backend = state == 'offline'
            ? _OfflineBackend()
            : RecoveryBackend(state == 'success' ? 202 : 503);
        backend.responseDelay = const Duration(seconds: 1);
        backend.delayedPaths.add('/auth/senha/recuperacao');
        await launch(tester, backend, textScale: 1.4);
        await tester.enterText(find.byType(TextFormField), 'user@example.com');
        await tester.ensureVisible(find.text('Enviar solicitação'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enviar solicitação'));
        await tester.pump();
        expect(find.text('Aguarde...'), findsOneWidget);
        expect(
          tester.widget<AuthTextField>(find.byType(AuthTextField)).enabled,
          isFalse,
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        final message = state == 'success'
            ? 'Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação.'
            : 'Não foi possível solicitar a recuperação. Tente novamente.';
        expect(find.text(message), findsOneWidget);
        await tester.ensureVisible(find.text(message));
        await tester.pumpAndSettle();
        expect(
          tester.widget<AuthTextField>(find.byType(AuthTextField)).enabled,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
