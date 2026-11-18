import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/system_ui_style.dart';
import 'content_header.dart';

Future<Brightness> backdropStatusIcons(
  ui.Image image,
  Size headerSize,
  double top,
  double statusHeight,
  Color background,
) async {
  final picture = ui.PictureRecorder();
  final canvas = Canvas(picture);
  const sampleSize = Size(24, 1);
  final input = Size(image.width.toDouble(), image.height.toDouble());
  final fitted = applyBoxFit(BoxFit.cover, input, headerSize);
  final crop = const Alignment(
    .3,
    0,
  ).inscribe(fitted.source, Offset.zero & input);
  final source = Rect.fromLTWH(
    crop.left,
    crop.top + top / headerSize.height * crop.height,
    crop.width,
    statusHeight / headerSize.height * crop.height,
  );
  canvas.drawColor(background, BlendMode.src);
  canvas.drawImageRect(image, source, Offset.zero & sampleSize, Paint());
  canvas.save();
  canvas.scale(
    sampleSize.width / headerSize.width,
    sampleSize.height / statusHeight,
  );
  canvas.translate(0, -top);
  for (final gradient in ContentHeader.backdropGradients(background)) {
    canvas.drawRect(
      Offset.zero & headerSize,
      Paint()..shader = gradient.createShader(Offset.zero & headerSize),
    );
  }
  canvas.restore();
  final recording = picture.endRecording();
  final sample = await recording.toImage(24, 1);
  recording.dispose();
  try {
    final bytes = (await sample.toByteData())!;
    var luminance = 0.0;
    for (var i = 0; i < 24; i++) {
      luminance += Color.fromARGB(
        255,
        bytes.getUint8(i * 4),
        bytes.getUint8(i * 4 + 1),
        bytes.getUint8(i * 4 + 2),
      ).computeLuminance();
    }
    // Equal contrast between black and white is at luminance ~0.179.
    return luminance / 24 > .179 ? Brightness.dark : Brightness.light;
  } finally {
    sample.dispose();
  }
}

class DetailsSystemUi extends StatefulWidget {
  const DetailsSystemUi({
    super.key,
    required this.backdrop,
    required this.builder,
  });
  final String? backdrop;
  final Widget Function(BuildContext, SystemUiOverlayStyle) builder;

  @override
  State<DetailsSystemUi> createState() => _DetailsSystemUiState();
}

class _DetailsSystemUiState extends State<DetailsSystemUi> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;
  Brightness? _icons;
  double _scroll = 0;
  int _revision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
    _sample();
  }

  @override
  void didUpdateWidget(covariant DetailsSystemUi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backdrop != widget.backdrop) _resolve();
  }

  void _resolve() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    _image = null;
    _icons = null;
    _revision++;
    final url = widget.backdrop;
    if (url == null || url.isEmpty) return;
    _stream = NetworkImage(url).resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, synchronous) {
        _image?.dispose();
        _image = info.image.clone();
        info.dispose();
        _sample();
      },
      onError: (Object error, StackTrace? stack) {
        // The header shows its themed placeholder if the backdrop cannot load.
      },
    );
    _stream!.addListener(_listener!);
  }

  Future<void> _sample() async {
    final revision = ++_revision;
    final height = MediaQuery.paddingOf(context).top;
    final headerSize = Size(MediaQuery.sizeOf(context).width, 350 + height);
    final background = Theme.of(context).scaffoldBackgroundColor;
    Brightness? icons;
    final image = _image?.clone();
    try {
      if (image != null && height > 0 && _scroll + height < headerSize.height) {
        icons = await backdropStatusIcons(
          image,
          headerSize,
          _scroll,
          height,
          background,
        );
      }
    } catch (_) {
      // Keep the theme fallback when image pixel readback is unavailable.
    } finally {
      image?.dispose();
    }
    if (mounted && revision == _revision && icons != _icons) {
      setState(() => _icons = icons);
    }
  }

  @override
  void dispose() {
    _revision++;
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = appSystemUiStyle(Theme.of(context), statusIcons: _icons);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 &&
            notification.metrics.axis == Axis.vertical &&
            (_scroll - notification.metrics.pixels).abs() >= 16) {
          _scroll = notification.metrics.pixels.clamp(0, double.infinity);
          _sample();
        }
        return false;
      },
      child: widget.builder(context, style),
    );
  }
}
