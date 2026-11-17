import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tv_score_front_flutter/widgets/edit_profile_sheet.dart';

import 'support/gallery.dart';

Future<void> openEditor(
  WidgetTester tester,
  Future<void> Function(String) onSave, {
  Future<void> Function(String, String)? onChangePassword,
  bool photoEditor = false,
}) async {
  final photo = ValueNotifier<String?>(null);
  addTearDown(photo.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEditProfileSheet(
              context,
              name: 'Victor',
              onSave: onSave,
              onChangePassword: onChangePassword,
              photoUrl: photoEditor ? photo : null,
              onUploadPhoto: (_, _) async {},
              onRemovePhoto: () async {},
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = previous);
  });
  testWidgets('valida nome, bloqueia envio repetido e fecha após salvar', (
    tester,
  ) async {
    final saved = <String>[];
    final pending = Completer<void>();
    await openEditor(tester, (name) async {
      saved.add(name);
      await pending.future;
    });
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Victor',
    );
    final save = find.widgetWithText(FilledButton, 'Salvar alterações');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.pumpAndSettle();
    expect(find.text('Informe seu nome.'), findsOneWidget);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField), '  Novo nome  ');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();
    expect(saved, ['Novo nome']);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Salvando...'),
          )
          .onPressed,
      isNull,
    );
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Informações da sua conta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final exit in ['X', 'fora', 'Voltar', 'arraste']) {
    testWidgets('confirma descarte por $exit e permite continuar editando', (
      tester,
    ) async {
      var requests = 0;
      await openEditor(tester, (_) async {
        requests++;
      });
      await tester.enterText(find.byType(TextFormField), 'Alterado');
      await tester.pumpAndSettle();
      Future<void> close() async {
        switch (exit) {
          case 'X':
            await tester.tap(find.byTooltip('Fechar edição de perfil'));
          case 'fora':
            await tester.tapAt(const Offset(5, 5));
          case 'Voltar':
            await tester.binding.handlePopRoute();
          case 'arraste':
            await tester.drag(find.text('Editar perfil'), const Offset(0, 100));
        }
        await tester.pumpAndSettle();
      }

      await close();
      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Alterado',
      );
      await close();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.text('Informações da sua conta'), findsNothing);
      expect(requests, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('erro mantém edição e permite nova tentativa', (tester) async {
    var requests = 0;
    await openEditor(tester, (_) async {
      requests++;
      if (requests == 1) throw StateError('Falha simulada');
    });
    await tester.enterText(find.byType(TextFormField), 'Outro nome');
    final save = find.widgetWithText(FilledButton, 'Salvar alterações');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível salvar o perfil. Tente novamente.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Outro nome',
    );
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Informações da sua conta'), findsNothing);
  });

  testWidgets('senha respeita descarte do nome e abre no mesmo sheet', (
    tester,
  ) async {
    await openEditor(tester, (_) async {}, onChangePassword: (_, _) async {});
    await tester.enterText(find.byType(TextFormField), 'Outro');
    await tester.ensureVisible(find.text('Alterar senha'));
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    await tester.tap(find.text('Alterar senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Senha atual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tela estreita com teclado rola sem overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var requests = 0;
    await openEditor(tester, (_) async {
      requests++;
    }, photoEditor: true);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(requests, 0);
    await tester.tap(find.byType(TextFormField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Novo');
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Salvar alterações'),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getBottomRight(
            find.widgetWithText(FilledButton, 'Salvar alterações'),
          )
          .dy,
      lessThanOrEqualTo(440),
    );
    expect(tester.takeException(), isNull);
  });
}
