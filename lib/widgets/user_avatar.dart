import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.imageBytes,
    this.size = 42,
    this.enableViewer = true,
  });
  final Uint8List? imageBytes;
  final String? name;
  final String? imageUrl;
  final double size;
  final bool enableViewer;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final avatar = ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: imageBytes != null
              ? Image.memory(
                  imageBytes!,
                  fit: BoxFit.cover,
                  cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .ceil(),
                  errorBuilder: (_, _, _) => fallback,
                )
              : imageUrl == null || imageUrl!.trim().isEmpty
              ? fallback
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : fallback,
                ),
        ),
      ),
    );
    if (!enableViewer ||
        (imageBytes == null && (imageUrl?.trim().isEmpty ?? true))) {
      return avatar;
    }
    return Semantics(
      button: true,
      label: 'Visualizar foto de perfil',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            showProfilePhoto(context, url: imageUrl, bytes: imageBytes),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(widthFactor: 1, heightFactor: 1, child: avatar),
        ),
      ),
    );
  }
}

Future<void> showProfilePhoto(
  BuildContext context, {
  String? url,
  Uint8List? bytes,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fechar foto',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(HugeIconsStroke.cancel01, color: Colors.white),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 360,
                      maxHeight: 360,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: bytes != null
                          ? Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              semanticLabel: 'Foto de perfil',
                            )
                          : Image.network(
                              url!,
                              fit: BoxFit.contain,
                              semanticLabel: 'Foto de perfil',
                              errorBuilder: (_, _, _) => Text(
                                'Não foi possível carregar a foto.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
