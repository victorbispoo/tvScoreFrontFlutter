import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/widgets/change_password_form.dart';

void main() {
  testWidgets('validação, visibilidade, erro, reenvio e sucesso sem duplicar', (
    tester,
  ) async {
    var calls = 0;
    var completed = false;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChangePasswordForm(
              onBusy: (_) {},
              onSuccess: () => completed = true,
              onSubmit: (current, next) async {
                expect(current, ' atual ');
                expect(next, ' senha nova ');
                calls++;
                if (calls == 1) {
                  throw const FormatException('Senha atual incorreta.');
                }
                await pending.future;
              },
            ),
          ),
        ),
      ),
    );
    final fields = find.byType(TextFormField);
    final submit = find.widgetWithText(FilledButton, 'Alterar senha');
    await tester.enterText(fields.at(0), ' atual ');
    await tester.enterText(fields.at(1), 'á' * 37);
    await tester.enterText(fields.at(2), 'diferente');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Use entre 8 e 72 bytes UTF-8.'), findsOneWidget);
    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(calls, 0);
    await tester.enterText(fields.at(1), ' senha nova ');
    await tester.enterText(fields.at(2), ' senha nova ');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Mostrar senha').first);
      await tester.pump();
    }
    expect(find.byTooltip('Ocultar senha'), findsNWidgets(3));
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Senha atual incorreta.'), findsOneWidget);
    await tester.tap(submit);
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 2);
    pending.complete();
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
