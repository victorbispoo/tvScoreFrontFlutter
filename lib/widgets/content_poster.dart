import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'skeleton_loading.dart';

class ContentPoster extends StatelessWidget {
  const ContentPoster({super.key, required this.content});

  final Map<String, String> content;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      (content['poster_path'] ?? '').replaceFirst(
        'image.tmdb.org/t/p/w500/',
        'image.tmdb.org/t/p/w342/',
      ),
      cacheWidth: 342,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const SkeletonBlock(),
      errorBuilder: (_, error, stack) => const ColoredBox(
        color: AppTheme.surfaceHighlight,
        child: Center(
          child: Icon(Icons.movie_outlined, size: 42, color: Colors.white54),
        ),
      ),
    ),
  );
}
