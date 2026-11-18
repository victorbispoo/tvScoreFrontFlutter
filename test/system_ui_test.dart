import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/system_ui_style.dart';
import 'package:tv_score_front_flutter/widgets/details_system_ui.dart';

void main() {
  test(
    'theme controls both Android bars independently of a backdrop override',
    () {
      for (final theme in [ThemeData.light(), ThemeData.dark()]) {
        final expected = theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light;
        final style = appSystemUiStyle(theme);
        expect(style.statusBarIconBrightness, expected);
        expect(style.systemNavigationBarIconBrightness, expected);
        expect(style.systemNavigationBarColor, theme.scaffoldBackgroundColor);
        final overridden = appSystemUiStyle(
          theme,
          statusIcons: Brightness.light,
        );
        expect(overridden.statusBarIconBrightness, Brightness.light);
        expect(overridden.systemNavigationBarIconBrightness, expected);
      }
    },
  );

  testWidgets(
    'samples light and dark backdrops after the actual header fades',
    (tester) async {
      for (final color in [Colors.white, Colors.black]) {
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawColor(color, BlendMode.src);
          final picture = recorder.endRecording();
          final image = await picture.toImage(100, 100);
          picture.dispose();
          final icons = await backdropStatusIcons(
            image,
            const Size(400, 380),
            0,
            30,
            Colors.black,
          );
          expect(
            icons,
            color == Colors.white ? Brightness.dark : Brightness.light,
          );
          image.dispose();
        });
      }
    },
  );

  testWidgets(
    'missing backdrop uses the theme and does not retain the previous route style',
    (tester) async {
      for (final theme in [ThemeData.light(), ThemeData.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: DetailsSystemUi(
              backdrop: '',
              builder: (context, style) =>
                  Scaffold(appBar: AppBar(systemOverlayStyle: style)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final style = tester
            .widget<AppBar>(find.byType(AppBar))
            .systemOverlayStyle!;
        expect(
          style.statusBarIconBrightness,
          theme.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
