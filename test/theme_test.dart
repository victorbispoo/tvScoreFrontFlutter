import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/core/light_logo_color_mapper.dart';
import 'package:tv_score_front_flutter/core/theme_controller.dart';
import 'package:tv_score_front_flutter/widgets/auth_text_field.dart';
import 'package:tv_score_front_flutter/widgets/floating_navigation_bar.dart';
import 'package:tv_score_front_flutter/widgets/tv_score_segmented_control.dart';

void main() {
  test('light wordmark keeps artwork colors', () {
    const mapper = LightLogoColorMapper();
    expect(
      mapper.substitute(null, 'path', 'fill', const Color(0xFFFBF9FA)),
      const Color(0xFF17263E),
    );
    expect(
      mapper.substitute(null, 'path', 'fill', const Color(0xFFFFD670)),
      const Color(0xFFFFD670),
    );
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test(
    'restores all modes and falls back to system for unknown values',
    () async {
      final controller = ThemeController.instance;
      await controller.restore();
      expect(controller.value, ThemeMode.system);
      for (final mode in ThemeMode.values) {
        await controller.select(mode);
        controller.value = ThemeMode.system;
        await controller.restore();
        expect(controller.value, mode);
      }
      await (await SharedPreferences.getInstance()).setString(
        ThemeController.preferenceKey,
        'invalid',
      );
      await controller.restore();
      expect(controller.value, ThemeMode.system);
    },
  );
  testWidgets(
    'theme changes preserve form state and follow system brightness',
    (tester) async {
      final controller = ThemeController.instance;
      await controller.restore();
      final field = TextEditingController();
      addTearDown(field.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: controller,
          builder: (context, mode, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: Scaffold(
              body: Column(
                children: [
                  AuthTextField(label: 'Nome', controller: field),
                  TvScoreSegmentedControl<ThemeMode>(
                    options: const {
                      ThemeMode.light: 'Claro',
                      ThemeMode.dark: 'Escuro',
                      ThemeMode.system: 'Sistema',
                    },
                    selectedValue: mode,
                    onChanged: controller.select,
                  ),
                ],
              ),
              bottomNavigationBar: FloatingNavigationBar(
                index: 2,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'Texto preservado');
      final state = tester.state(find.byType(AuthTextField));
      for (final mode in [ThemeMode.dark, ThemeMode.light]) {
        await controller.select(mode);
        await tester.pumpAndSettle();
        expect(
          identical(tester.state(find.byType(AuthTextField)), state),
          isTrue,
        );
        expect(field.text, 'Texto preservado');
        expect(
          Theme.of(tester.element(find.byType(AuthTextField))).brightness,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
        expect(tester.takeException(), isNull);
      }
      await controller.select(ThemeMode.system);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AuthTextField))).brightness,
        Brightness.dark,
      );
    },
  );
}
