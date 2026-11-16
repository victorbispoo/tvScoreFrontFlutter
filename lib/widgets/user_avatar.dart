import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.imageBytes,
    this.size = 42,
  });
  final Uint8List? imageBytes;
  final String? name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name?.trim() ?? '';
    final fallback = ColoredBox(
      color: AppTheme.surfaceHighlight,
      child: Center(
        child: Text(
          trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    return ExcludeSemantics(
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
  }
}
