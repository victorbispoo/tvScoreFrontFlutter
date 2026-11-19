import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';
import 'support/backend_http.dart';
import 'support/gallery.dart';

void main() {
  setUp(() async {
    final previous = ImagePickerPlatform.instance;
    ImagePickerPlatform.instance = TestGallery();
    addTearDown(() => ImagePickerPlatform.instance = previous);
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await ApiService().open('victor@teste.com', 'Victor');
  });
  for (final width in [320.0, 390.0, 768.0, 1024.0, 1366.0, 1920.0]) {
    for (final ratings in [
      <double>[],
      [0.0, 8.0, 10.0],
    ]) {
      testWidgets(
        'perfil calcula média de $ratings com uma consulta em $width dp',
        (tester) async {
          final backend = BackendHttp();
          final previous = HttpOverrides.current;
          HttpOverrides.global = backend;
          addTearDown(() => HttpOverrides.global = previous);
          ApiService.token = 'test-token';
          ApiService.savedContents = [];
          ApiService.userName = 'Victor';
          ApiService.userEmail = 'victor@teste.com';
          backend.reviews.addAll(ratings.map((rating) => {'nota': rating}));
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 800);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              onGenerateRoute: AppRoutes.generate,
              theme: ratings.isEmpty ? ThemeData.light() : ThemeData.dark(),
              home: const Scaffold(body: ProfilePage()),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Média'), findsOneWidget);
          final wide = width >= 768;
          expect(
            tester.widget<UserAvatar>(find.byType(UserAvatar)).size,
            wide ? 116 : 72,
          );
          expect(
            tester.widget<Text>(find.text('Victor')).style?.fontSize,
            wide ? 34 : 22,
          );
          final library = tester.getTopLeft(find.text('Sua biblioteca'));
          final settings = tester.getTopLeft(find.text('Personalização'));
          if (width >= 768) {
            expect(settings.dx, greaterThan(library.dx));
            expect(settings.dy, library.dy);
          } else {
            expect(settings.dy, greaterThan(library.dy));
          }
          if (width >= 1024) {
            final cells = find.byType(TableCell);
            expect(cells, findsNWidgets(2));
            final libraryCard = tester.getRect(cells.first);
            final personalizationCard = tester.getRect(cells.last);
            expect(personalizationCard.top, libraryCard.top);
            expect(personalizationCard.bottom, libraryCard.bottom);
            final logout = tester.getRect(
              find.widgetWithText(TextButton, 'Sair da conta'),
            );
            expect(logout.top, greaterThan(libraryCard.bottom));
            expect(logout.center.dx, closeTo(width / 2, .01));
          }
          expect(find.text(ratings.isEmpty ? '—' : '6.0'), findsOneWidget);
          expect(
            backend.requests.where(
              (request) => request == 'GET /avaliacoes/minhas',
            ),
            hasLength(1),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Editar perfil'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField),
            'Victor atualizado',
          );
          final save = find.text('Salvar alterações');
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(ApiService.userName, 'Victor atualizado');
          expect(find.text('Victor atualizado'), findsOneWidget);
          expect(
            backend.requests.where((request) => request == 'PUT /usuarios/eu'),
            hasLength(1),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Editar perfil'));
          await tester.pumpAndSettle();
          expect(find.text('Informações da sua conta'), findsOneWidget);
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField))
                .controller!
                .text,
            'Victor atualizado',
          );
          await tester.tap(find.byTooltip('Fechar edição de perfil'));
          await tester.pumpAndSettle();
          expect(find.text('Informações da sua conta'), findsNothing);
          expect(tester.takeException(), isNull);
        },
        variant: const TargetPlatformVariant({TargetPlatform.windows}),
      );
    }
  }
}
