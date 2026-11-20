import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/widgets/cinematic_poster_composition.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

import 'support/gallery.dart';

void main() {
  setUp(() {
    final gallery = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = gallery);
    final dispatcher =
        TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'Registration shares cinematic layout and fits short screens, dark=$dark',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1366, 640);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const RegisterPage(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Ana');
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
          final avatar = tester.getRect(find.byType(UserAvatar));
          final camera = tester.getRect(find.byTooltip('Escolher foto'));
          expect(avatar.width, closeTo(92, .01));
          expect(avatar.height, closeTo(92, .01));
          expect(avatar.center.dx, closeTo(form.center.dx, .01));
          expect(camera.width, closeTo(48, .01));
          expect(camera.height, closeTo(48, .01));
          expect(avatar.overlaps(camera), isTrue);
          final composition = tester.widget<CinematicPosterComposition>(
            find.byType(CinematicPosterComposition),
          );
          expect(composition.compact, width < 1024);
          expect(composition.collageAsset, 'lib/assets/colagemLogin.jpg');
          if (width >= 1024) {
            expect(
              tester.getRect(find.byType(CinematicPosterComposition)).right,
              lessThan(form.left),
            );
          }
          expect(find.text('Crie sua conta'), findsOneWidget);
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).first)
                .controller!
                .text,
            'Ana',
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Cadastrar'));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.text('Cadastrar')).bottom,
            lessThanOrEqualTo(340),
          );
          expect(tester.takeException(), isNull);
        }
      },
      variant: const TargetPlatformVariant({TargetPlatform.windows}),
    );
  }
  for (final dark in [false, true]) {
    for (final width in [360.0, 390.0, 1366.0, 1920.0]) {
      testWidgets('Login dark=$dark width=$width with keyboard', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const LoginPage(),
          ),
        );
        await tester.pumpAndSettle();
        final composition = tester.widget<CinematicPosterComposition>(
          find.byType(CinematicPosterComposition),
        );
        expect(composition.compact, width < 1024);
        expect(find.byType(Image), findsNWidgets(width < 1024 ? 4 : 6));
        final collage = find.image(
          ResizeImage(
            const AssetImage('lib/assets/colagemLogin.jpg'),
            width: width < 1024 ? 720 : 1440,
          ),
        );
        expect(collage, findsOneWidget);
        final collageBounds = tester.getRect(collage);
        final compositionBounds = tester.getRect(
          find.byType(CinematicPosterComposition),
        );
        expect(
          collageBounds.left,
          greaterThanOrEqualTo(compositionBounds.left - .01),
        );
        expect(
          collageBounds.right,
          lessThanOrEqualTo(compositionBounds.right + .01),
        );
        if (width >= 1024) {
          expect(
            collageBounds.right,
            lessThan(tester.getRect(find.byType(Form)).left),
          );
        } else {
          expect(
            collageBounds.bottom,
            lessThan(tester.getRect(find.byType(Form)).top),
          );
        }
        expect(find.textContaining('indispon'), findsNothing);
        if (width < 1024) {
          final band = tester.getSize(find.byType(CinematicPosterComposition));
          expect(band.height, inInclusiveRange(120, 170));
        }
        await tester.enterText(find.byType(TextFormField).last, 'senha-teste');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Continuar explorando'));
        await tester.pumpAndSettle();
        final button = tester.getRect(find.text('Continuar explorando'));
        expect(button.bottom, lessThanOrEqualTo(500));
        expect(tester.takeException(), isNull);
      }, variant: const TargetPlatformVariant({TargetPlatform.windows}));
    }
  }
  testWidgets('Explore opens public Home without authentication', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LoginPage(),
        routes: {
          AppRoutes.home: (_) => const Scaffold(body: Text('Home publica')),
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar explorando'));
    await tester.tap(find.text('Continuar explorando'));
    await tester.pumpAndSettle();
    expect(find.text('Home publica'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
  testWidgets('Explore preserves contextual origin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginPage(returnToOrigin: true),
                ),
              ),
              child: const Text('Origin'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Origin'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continuar explorando'));
    await tester.tap(find.text('Continuar explorando'));
    await tester.pumpAndSettle();
    expect(find.text('Origin'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });
  testWidgets(
    'login mantém o formulário ao redimensionar e aceita Tab e Enter',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1366, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      expect(
        tester.widget<EditableText>(fields.first).focusNode.hasFocus,
        isTrue,
      );
      await tester.enterText(fields.first, 'email-invalido');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(fields.last).focusNode.hasFocus,
        isTrue,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Por favor, insira sua senha.'), findsOneWidget);

      for (final width in [360.0, 390.0, 768.0, 1024.0, 1366.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpAndSettle();
        final logo = tester.getRect(find.byType(SvgPicture));
        final form = tester.getRect(find.byType(Form));
        if (width >= 1366) {
          expect(
            tester.getRect(find.byType(CinematicPosterComposition)).right,
            lessThan(form.left),
          );
          expect(form.width, closeTo(356, .01));
        } else {
          expect(logo.bottom, lessThanOrEqualTo(form.top));
        }
        expect(
          tester.widget<EditableText>(fields.first).controller.text,
          'email-invalido',
        );
        expect(tester.takeException(), isNull);
      }
    },
    variant: const TargetPlatformVariant({TargetPlatform.windows}),
  );
}
