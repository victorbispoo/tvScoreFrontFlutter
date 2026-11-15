import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_snackbar.dart';

void main() {
  testWidgets('exibe as quatro variantes com HugeIconsStroke', (tester) async {
    const variants = <(String, IconData, void Function(BuildContext, String))>[
      ('Sucesso', HugeIconsStroke.checkmarkCircle01, TvScoreSnackbar.success),
      ('Erro', HugeIconsStroke.alertCircle, TvScoreSnackbar.error),
      ('Aviso', HugeIconsStroke.alert02, TvScoreSnackbar.warning),
      ('Informação', HugeIconsStroke.informationCircle, TvScoreSnackbar.info),
    ];

    for (final (label, icon, show) in variants) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(label),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => show(context, label),
                child: const Text('Mostrar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mostrar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(label), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mensagem longa e ação de retry cabem em tela estreita', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => TvScoreSnackbar.error(
                context,
                'Não foi possível carregar mais resultados. Verifique sua conexão e tente novamente.',
                actionLabel: 'Tentar novamente',
                onAction: () => retried = true,
              ),
              child: const Text('Mostrar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mostrar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    final action = find.byType(SnackBarAction);
    expect(action, findsOneWidget);
    tester.widget<SnackBarAction>(action).onPressed();
    expect(retried, isTrue);
  });

  testWidgets('usa margem contextual quando a navegação flutuante existe', (
    tester,
  ) async {
    for (final hasNavigation in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(hasNavigation),
          home: hasNavigation
              ? TvScoreSnackbar.withFloatingNavigation(
                  child: Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () => TvScoreSnackbar.info(context, 'Info'),
                        child: const Text('Mostrar'),
                      ),
                    ),
                  ),
                )
              : Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => TvScoreSnackbar.info(context, 'Info'),
                      child: const Text('Mostrar'),
                    ),
                  ),
                ),
        ),
      );
      await tester.tap(find.text('Mostrar'));
      await tester.pump(const Duration(milliseconds: 300));
      final snackbar = tester.widget<SnackBar>(find.byType(SnackBar));
      final safeBottom = MediaQuery.paddingOf(
        tester.element(find.text('Mostrar')),
      ).bottom;
      expect(
        snackbar.margin!.resolve(TextDirection.ltr).bottom,
        hasNavigation ? 80 + safeBottom : 16,
      );
    }
  });
}
