import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/pages/login_page.dart';

void main() {
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

      for (final width in [390.0, 768.0, 1024.0, 1366.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpAndSettle();
        final logo = tester.getRect(find.byType(SvgPicture));
        final form = tester.getRect(find.byType(Form));
        if (width >= 1366) {
          expect(logo.right, lessThan(form.left));
          expect(form.width, 440);
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
