import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_services.dart';
import 'profile_photo_crop_page.dart';
import 'user_avatar.dart';

class ProfilePhotoEditor extends StatefulWidget {
  const ProfilePhotoEditor({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onUpload,
    required this.onRemove,
    required this.onBusy,
    required this.onPendingChanged,
    this.enabled = true,
    this.photoBytes,
  });

  final String name;
  final ValueListenable<String?> photoUrl;
  final Future<void> Function(Uint8List, void Function(int, int)) onUpload;
  final Future<void> Function() onRemove;
  final ValueChanged<bool> onBusy;
  final ValueChanged<bool> onPendingChanged;
  final bool enabled;
  final Uint8List? photoBytes;

  @override
  State<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<ProfilePhotoEditor> {
  final _picker = ImagePicker();
  Uint8List? _selected;
  bool _busy = false;
  bool _confirmingRemoval = false;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverSelection());
    }
  }

  Future<void> _recoverSelection() async {
    if (!mounted) return;
    await _run(() async {
      final result = await _picker.retrieveLostData();
      if (result.files?.isNotEmpty ?? false) {
        await _preview(result.files!.first);
      }
    });
  }

  Future<void> _preview(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Escolha uma imagem de até 5 MiB.');
    }
    final bytes = await file.readAsBytes();
    ApiService.profilePhotoMimeType(bytes);
    final prepared = await compute(prepareProfilePhoto, bytes);
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => ProfilePhotoCropPage(bytes: prepared)),
    );
    if (!mounted || cropped == null) return;
    setState(() {
      _selected = cropped;
      _error = null;
    });
    widget.onPendingChanged(true);
    await _uploadSelected();
  }

  Future<void> _pick() async {
    if (_busy || !widget.enabled) return;
    await _run(() async {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (file != null) await _preview(file);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    widget.onBusy(true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Não foi possível atualizar a foto. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy(false);
      }
    }
  }

  void _cancel() {
    setState(() {
      _selected = null;
      _error = null;
    });
    widget.onPendingChanged(false);
  }

  Future<void> _upload() async {
    if (_busy || !widget.enabled || _selected == null) return;
    await _run(_uploadSelected);
  }

  Future<void> _uploadSelected() async {
    await widget.onUpload(_selected!, (sent, total) {
      if (mounted) {
        setState(() => _progress = total > 0 ? sent / total : null);
      }
    });
    if (mounted) _cancel();
  }

  Future<void> _remove() async {
    if (_busy || !widget.enabled) return;
    _confirmingRemoval = true;
    // Lock the parent editor while the confirmation dialog is open too.
    await _run(() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remover foto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _confirmingRemoval = false);
      if (confirmed == true && mounted) await widget.onRemove();
    });
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: widget.photoUrl,
    builder: (context, url, _) {
      final bytes = _error == null
          ? _selected ?? widget.photoBytes
          : widget.photoBytes;
      final hasPhoto = url?.trim().isNotEmpty == true || bytes != null;
      return Column(
        children: [
          Stack(
            children: [
              Semantics(
                button: hasPhoto,
                label: hasPhoto
                    ? 'Visualizar foto de perfil'
                    : 'Avatar de ${widget.name}',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: !_busy && widget.enabled && hasPhoto
                        ? () =>
                              showProfilePhoto(context, url: url, bytes: bytes)
                        : null,
                    child: Ink(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      child: UserAvatar(
                        enableViewer: false,
                        name: widget.name,
                        imageUrl: url,
                        imageBytes: bytes,
                        size: 120,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton.filled(
                  tooltip: 'Escolher foto',
                  onPressed: _busy || !widget.enabled ? null : _pick,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.surface,
                      width: 3,
                    ),
                  ),
                  icon: const Icon(HugeIconsStroke.camera01, size: 22),
                ),
              ),
            ],
          ),
          if (_selected == null && hasPhoto)
            TextButton(
              onPressed: _busy || !widget.enabled ? null : _remove,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Remover foto'),
            )
          else if (_selected != null)
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: _busy || !widget.enabled ? null : _upload,
                  child: const Text('Confirmar foto'),
                ),
                TextButton(
                  onPressed: _busy || !widget.enabled ? null : _cancel,
                  child: const Text('Cancelar foto'),
                ),
              ],
            ),
          if (_busy && !_confirmingRemoval)
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(value: _progress),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    },
  );
}
