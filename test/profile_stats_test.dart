import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/pages/profile_page.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
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
  for (final width in [320.0, 390.0, 600.0]) {
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
          await tester.binding.setSurfaceSize(Size(width, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              onGenerateRoute: AppRoutes.generate,
              theme: ThemeData.dark(),
              home: const Scaffold(body: ProfilePage()),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Média'), findsOneWidget);
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
      );
    }
  }
}
