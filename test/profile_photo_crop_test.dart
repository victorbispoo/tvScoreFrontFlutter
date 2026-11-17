import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tv_score_front_flutter/widgets/profile_photo_crop_page.dart';

import 'profile_photo_test.dart' as support;

void main() {
  test(
    'JPEG output caps size, keeps small images and rejects invalid data',
    () {
      for (final side in [12, 512, 700]) {
        final output = encodeProfilePhoto(
          img.encodePng(img.Image(width: side, height: side)),
        );
        expect(output.take(3), [255, 216, 255]);
        final decoded = img.decodeJpg(output)!;
        expect(decoded.width, side > 512 ? 512 : side);
        expect(decoded.height, decoded.width);
      }
      expect(
        () =>
            encodeProfilePhoto(img.encodePng(img.Image(width: 12, height: 24))),
        throwsFormatException,
      );
      expect(() => prepareProfilePhoto(Uint8List(0)), throwsFormatException);
    },
  );

  test('normalizes all EXIF orientations before preview', () {
    for (var orientation = 1; orientation <= 8; orientation++) {
      final source = img.Image(width: 30, height: 20);
      source.setPixelRgb(0, 0, 255, 0, 0);
      source.exif.imageIfd.orientation = orientation;
      final jpeg = img.encodeJpg(source);
      final expected = img.bakeOrientation(img.decodeJpg(jpeg)!);
      final prepared = img.decodePng(prepareProfilePhoto(jpeg))!;
      expect(prepared.width, expected.width);
      expect(prepared.height, expected.height);
      expect(prepared.getBytes(), expected.getBytes());
    }
  });

  for (final dimensions in [(180, 300), (300, 180), (20, 30)]) {
    testWidgets(
      'preview matches square output after zoom and bounded drag $dimensions',
      (tester) async {
        final source = img.Image(width: dimensions.$1, height: dimensions.$2);
        for (final pixel in source) {
          pixel.setRgb(
            pixel.x * 255 ~/ source.width,
            pixel.y * 255 ~/ source.height,
            80,
          );
        }
        img.Image? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final bytes = await Navigator.push(
                    context,
                    MaterialPageRoute<Uint8List>(
                      builder: (_) =>
                          ProfilePhotoCropPage(bytes: img.encodePng(source)),
                    ),
                  );
                  if (bytes != null) result = img.decodeJpg(bytes);
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await support.waitForCrop(tester);
        final crop = find.byType(Crop);
        final frame = find.descendant(
          of: crop,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        Rect imageRect() => tester.getRect(
          find.descendant(of: crop, matching: find.byType(Image)).first,
        );
        final cropRect = tester.getRect(frame);
        void checkCoverage() {
          final image = imageRect();
          expect(image.left, lessThanOrEqualTo(cropRect.left + .01));
          expect(image.top, lessThanOrEqualTo(cropRect.top + .01));
          expect(image.right, greaterThanOrEqualTo(cropRect.right - .01));
          expect(image.bottom, greaterThanOrEqualTo(cropRect.bottom - .01));
        }

        checkCoverage();
        final center = cropRect.center;
        final first = await tester.startGesture(
          center - const Offset(30, 0),
          pointer: 1,
        );
        final second = await tester.startGesture(
          center + const Offset(30, 0),
          pointer: 2,
        );
        await tester.pump();
        for (final distance in [60.0, 100.0, 180.0, 30.0, 5.0, 60.0]) {
          await first.moveTo(center - Offset(distance, 0));
          await second.moveTo(center + Offset(distance, 0));
          await tester.pump();
          checkCoverage();
        }
        await first.up();
        await second.up();
        for (final offset in [
          const Offset(2000, 2000),
          const Offset(-2000, -2000),
        ]) {
          await tester.drag(crop, offset);
          await tester.pump();
          checkCoverage();
        }
        final image = imageRect();
        final expectedX =
            (cropRect.left - image.left) / image.width * source.width;
        final expectedY =
            (cropRect.top - image.top) / image.height * source.height;
        await tester.tap(find.text('Salvar foto'));
        await support.finishCrop(tester);
        expect(result, isNotNull);
        expect(result!.width, result!.height);
        expect(result!.width, lessThanOrEqualTo(dimensions.$1));
        final pixel = result!.getPixel(result!.width ~/ 2, result!.height ~/ 2);
        final expected = source.getPixel(
          expectedX.toInt() + result!.width ~/ 2,
          expectedY.toInt() + result!.height ~/ 2,
        );
        expect(pixel.r, closeTo(expected.r, 4));
        expect(pixel.g, closeTo(expected.g, 4));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
