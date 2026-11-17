import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:tv_score_front_flutter/services/api_services.dart';
import 'package:tv_score_front_flutter/widgets/community_review_card.dart';
import 'package:tv_score_front_flutter/widgets/edit_profile_sheet.dart';
import 'package:tv_score_front_flutter/widgets/profile_photo_crop_page.dart';
import 'package:tv_score_front_flutter/widgets/profile_photo_editor.dart';
import 'package:tv_score_front_flutter/widgets/user_avatar.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl6ZQAAAABJRU5ErkJggg==',
);

class Gallery extends ImagePickerPlatform {
  XFile? file;
  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    expect(source, ImageSource.gallery);
    return file;
  }

  @override
  Future<LostDataResponse> getLostData() async => LostDataResponse.empty();
}

Future<void> waitForCrop(WidgetTester tester) async {
  for (var i = 0; i < 150; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    final button = find.widgetWithText(FilledButton, 'Salvar foto');
    if (button.evaluate().isNotEmpty &&
        tester.widget<FilledButton>(button).onPressed != null) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  fail('Crop did not become ready');
}

Future<void> finishCrop(WidgetTester tester) async {
  for (var i = 0; i < 150; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(ProfilePhotoCropPage).evaluate().isEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Crop did not finish');
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ApiService.token = 'session';
    ApiService.userPhotoUrl.value = 'https://example.com/old.png';
  });

  test(
    'multipart contains file bytes, MIME type and bearer; delete clears URL',
    () async {
      final api = ApiService();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            expect(options.path, '/usuarios/eu/foto');
            expect(options.headers['Authorization'], 'Bearer session');
            if (options.method == 'PUT') {
              final form = options.data as FormData;
              expect(form.files.single.key, 'arquivo');
              final file = form.files.single.value;
              expect(file.contentType.toString(), 'image/png');
              expect(
                await file.finalize().expand((bytes) => bytes).toList(),
                png,
              );
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'nome': 'Ana',
                    'email': 'ana@test.com',
                    'fotoUrl': 'https://example.com/new.png',
                  },
                ),
              );
            } else {
              expect(options.method, 'DELETE');
              handler.resolve(
                Response(requestOptions: options, statusCode: 204),
              );
            }
          },
        ),
      );
      await api.uploadProfilePhoto(png);
      expect(ApiService.userPhotoUrl.value, 'https://example.com/new.png');
      await api.removeProfilePhoto();
      expect(ApiService.userPhotoUrl.value, isNull);
    },
  );

  test('validates actual format and 5 MiB limit before upload', () async {
    final api = ApiService();
    await expectLater(
      api.uploadProfilePhoto(Uint8List(0)),
      throwsFormatException,
    );
    await expectLater(
      api.uploadProfilePhoto(Uint8List.fromList([71, 73, 70, 56])),
      throwsFormatException,
    );
    await expectLater(
      api.uploadProfilePhoto(Uint8List(5 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
    expect(
      ApiService.profilePhotoMimeType(Uint8List.fromList([255, 216, 255])),
      'image/jpeg',
    );
    expect(ApiService.userPhotoUrl.value, 'https://example.com/old.png');
  });

  for (final status in [400, 413, 415, 503, 401]) {
    test('HTTP $status preserves previous photo', () async {
      final api = ApiService();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: status),
              ),
            );
          },
        ),
      );
      await expectLater(api.uploadProfilePhoto(png), throwsFormatException);
      await expectLater(api.removeProfilePhoto(), throwsFormatException);
      expect(ApiService.userPhotoUrl.value, 'https://example.com/old.png');
    });
  }

  for (final operation in ['upload', 'delete', 'load']) {
    test('pending $operation cannot update another session', () async {
      final api = ApiService();
      final started = Completer<void>();
      final release = Completer<void>();
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            started.complete();
            await release.future;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: operation == 'delete' ? 204 : 200,
                data: {'fotoUrl': 'https://example.com/stale.png'},
              ),
            );
          },
        ),
      );
      final pending = switch (operation) {
        'upload' => api.uploadProfilePhoto(png),
        'delete' => api.removeProfilePhoto(),
        _ => api.loadProfilePhoto(),
      };
      final check = expectLater(pending, throwsStateError);
      await started.future;
      await api.logout();
      expect(ApiService.userPhotoUrl.value, isNull);
      ApiService.token = 'new-session';
      ApiService.userPhotoUrl.value = 'https://example.com/other.png';
      release.complete();
      await check;
      expect(ApiService.userPhotoUrl.value, 'https://example.com/other.png');
    });
  }

  Future<Gallery> gallery() async {
    final previous = ImagePickerPlatform.instance;
    final fake = Gallery()
      ..file = XFile.fromData(
        img.encodePng(img.Image(width: 80, height: 120)),
        name: 'photo.png',
        mimeType: 'image/png',
      );
    ImagePickerPlatform.instance = fake;
    addTearDown(() => ImagePickerPlatform.instance = previous);
    return fake;
  }

  testWidgets(
    'preview, cancel, failure, retry, progress and remove confirmation',
    (tester) async {
      await gallery();
      final photo = ValueNotifier<String?>(null);
      addTearDown(photo.dispose);
      var uploads = 0;
      var removed = 0;
      var pending = false;
      final release = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePhotoEditor(
              name: 'Ana',
              photoUrl: photo,
              onBusy: (_) {},
              onPendingChanged: (value) => pending = value,
              onUpload: (bytes, progress) async {
                uploads++;
                expect(ApiService.profilePhotoMimeType(bytes), 'image/jpeg');
                final output = img.decodeJpg(bytes)!;
                expect(output.width, output.height);
                expect(output.width, lessThanOrEqualTo(80));
                if (uploads == 1) throw const FormatException('Falha simulada');
                progress(1, 2);
                await release.future;
                photo.value = 'https://example.com/new.png';
              },
              onRemove: () async {
                removed++;
                photo.value = null;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher foto'));
      await waitForCrop(tester);
      expect(uploads, 0);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(pending, isFalse);
      await tester.tap(find.text('Escolher foto'));
      await waitForCrop(tester);
      await tester.tap(find.text('Salvar foto'));
      await finishCrop(tester);
      expect(find.text('Falha simulada'), findsOneWidget);
      expect(pending, isTrue);
      expect(photo.value, isNull);
      await tester.tap(find.text('Confirmar foto'));
      await tester.pump();
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .5,
      );
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Confirmar foto'),
            )
            .onPressed,
        isNull,
      );
      release.complete();
      await tester.pumpAndSettle();
      expect(pending, isFalse);
      expect(
        tester.widget<UserAvatar>(find.byType(UserAvatar)).imageUrl,
        photo.value,
      );
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(removed, 0);
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(removed, 1);
      expect(photo.value, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled crop preserves name and editor discard', (
    tester,
  ) async {
    await gallery();
    final photo = ValueNotifier<String?>(null);
    addTearDown(photo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEditProfileSheet(
                context,
                name: 'Ana',
                onSave: (_) async {},
                photoUrl: photo,
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
    await tester.enterText(find.byType(TextFormField), 'Outro nome');
    await tester.ensureVisible(find.text('Escolher foto'));
    await tester.tap(find.text('Escolher foto'));
    await waitForCrop(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Fechar edição de perfil'));
    await tester.tap(find.byTooltip('Fechar edição de perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Outro nome',
    );
    expect(find.text('Escolher foto'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar edição de perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePhotoEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('community DTO passes optional photo without user requests', (
    tester,
  ) async {
    for (final url in [null, 'https://example.com/community.png']) {
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityReviewCard.fromJson({
            'id': 1,
            'nomeUsuario': 'Ana',
            'nota': 8,
            'fotoUsuarioUrl': url,
          }),
        ),
      );
      expect(tester.widget<UserAvatar>(find.byType(UserAvatar)).imageUrl, url);
    }
  });
}
