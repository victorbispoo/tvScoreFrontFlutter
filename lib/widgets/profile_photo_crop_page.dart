import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

Uint8List prepareProfilePhoto(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) throw const FormatException('A imagem é inválida.');
  return img.encodePng(img.bakeOrientation(image));
}

Uint8List encodeProfilePhoto(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null || image.width != image.height) {
    throw const FormatException('Não foi possível recortar a foto.');
  }
  final resized = image.width > 512
      ? img.copyResize(
          image,
          width: 512,
          height: 512,
          interpolation: img.Interpolation.average,
        )
      : image;
  return img.encodeJpg(resized, quality: 85);
}

class ProfilePhotoCropPage extends StatefulWidget {
  const ProfilePhotoCropPage({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<ProfilePhotoCropPage> createState() => _ProfilePhotoCropPageState();
}

class _ProfilePhotoCropPageState extends State<ProfilePhotoCropPage> {
  final _controller = CropController();
  bool _ready = false;
  bool _saving = false;
  String? _error;

  Future<void> _cropped(CropResult result) async {
    try {
      if (result is! CropSuccess) {
        throw const FormatException('Não foi possível recortar a foto.');
      }
      final bytes = await compute(encodeProfilePhoto, result.croppedImage);
      if (mounted) Navigator.pop(context, bytes);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível recortar a foto. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      title: const Text('Ajustar foto'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 560,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AbsorbPointer(
                    absorbing: _saving,
                    child: Crop(
                      image: widget.bytes,
                      controller: _controller,
                      onCropped: _cropped,
                      interactive: true,
                      fixCropRect: true,
                      withCircleUi: true,
                      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                        size: .8,
                        aspectRatio: 1,
                      ),
                      baseColor: Theme.of(context).scaffoldBackgroundColor,
                      maskColor: Colors.black.withValues(alpha: .65),
                      cornerDotBuilder: (_, _) => const SizedBox.shrink(),
                      overlayBuilder: (_, rect) => IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38),
                          ),
                        ),
                      ),
                      willUpdateScale: (scale) => scale <= 5,
                      onStatusChanged: (status) {
                        if (mounted) {
                          setState(() => _ready = status == CropStatus.ready);
                        }
                      },
                      progressIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Arraste para posicionar e use dois dedos para ampliar.',
              textAlign: TextAlign.center,
            ),
          ),
          if (_saving) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, semanticsLabel: _error),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: !_ready || _saving
                      ? null
                      : () {
                          setState(() => _saving = true);
                          // The circular mask is visual only. crop() returns a square.
                          _controller.crop();
                        },
                  child: const Text('Salvar foto'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
