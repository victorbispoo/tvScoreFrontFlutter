import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';
import 'package:tv_score_front_flutter/pages/register_page.dart';
import 'package:tv_score_front_flutter/widgets/auth_text_field.dart';

import 'support/gallery.dart';

void main() {
  setUp(() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = previous);
  });
  for (final login in [true, false]) {
    testWidgets(
      '${login ? 'login' : 'cadastro'} mantém digitação, foco e senha',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.generate,
            theme: AppTheme.dark,
            home: login ? const LoginPage() : const RegisterPage(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AuthTextField), findsNWidgets(login ? 2 : 3));
        final email = find.byType(TextFormField).at(login ? 0 : 1);
        await tester.ensureVisible(email);
        await tester.pumpAndSettle();
        await tester.tap(email);
        await tester.enterText(email, 'pessoa@teste.com');
        await tester.pumpAndSettle();
        final emailWidget = tester.widget<TextFormField>(email);
        expect(
          tester
              .widget<EditableText>(
                find.descendant(of: email, matching: find.byType(EditableText)),
              )
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(emailWidget.controller!.text, 'pessoa@teste.com');
        final password = find.byType(TextFormField).last;
        await tester.ensureVisible(password);
        await tester.pumpAndSettle();
        await tester.enterText(password, 'senha-segura');
        await tester.pumpAndSettle();
        EditableText passwordInput() => tester.widget<EditableText>(
          find.descendant(of: password, matching: find.byType(EditableText)),
        );
        expect(passwordInput().obscureText, isTrue);
        final show = find.byTooltip('Mostrar senha');
        expect(tester.getSize(show).height, greaterThanOrEqualTo(48));
        await tester.tap(show);
        await tester.pumpAndSettle();
        expect(passwordInput().obscureText, isFalse);
        expect(passwordInput().controller.text, 'senha-segura');
        await tester.tap(find.byTooltip('Ocultar senha'));
        await tester.pumpAndSettle();
        expect(passwordInput().obscureText, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('login preserva mensagens de validação e bordas de erro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: AppTheme.dark,
        home: const LoginPage(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'invalido');
    await tester.enterText(find.byType(TextFormField).last, 'abc');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Por favor, insira um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro bloqueia e-mail inválido e senha curta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: AppTheme.dark,
        home: const RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
    await tester.enterText(find.byType(TextFormField).at(1), 'email-invalido');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Por favor, insira um e-mail válido.'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cadastro apresenta avatar inativo e link para entrar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: AppTheme.dark,
        home: const RegisterPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(find.byIcon(HugeIconsStroke.camera01), findsOneWidget);
    expect(find.text('J\u00e1 tem uma conta?'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login reduz a caixa da logo original para 170 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: AppTheme.dark,
        home: const LoginPage(),
      ),
    );
    final logo = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.byType(SvgPicture),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(logo.width, 170);
    expect(logo.height, 170);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campo desabilitado preserva conteúdo e bloqueia mostrar senha', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'senha');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRoutes.generate,
        theme: AppTheme.dark,
        home: Scaffold(
          body: AuthTextField(
            label: 'Senha',
            controller: controller,
            isPassword: true,
            enabled: false,
          ),
        ),
      ),
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
    expect(controller.text, 'senha');
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Mostrar senha',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
