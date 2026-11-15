import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import 'content_poster.dart';
import 'skeleton_loading.dart';

class ContentHeader extends StatelessWidget {
  const ContentHeader({
    super.key,
    required this.content,
    required this.onFavoritePressed,
    required this.isSaved,
    this.heroTag,
  });

  final Map<String, String> content;
  final VoidCallback? onFavoritePressed;
  final bool isSaved;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final backdrop = content['backdrop_path'];
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return Center(
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 350 + (MediaQuery.of(context).padding.top),
            child: Image.network(
              backdrop ?? '',
              fit: BoxFit.cover,
              alignment: const Alignment(0.3, 0),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const SkeletonBlock(radius: 0),
              errorBuilder: (_, error, stackTrace) => const Center(
                child: Icon(
                  HugeIconsStroke.film01,
                  size: 48,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    backgroundColor.withValues(alpha: 0.05),
                    backgroundColor.withValues(alpha: 0.15),
                    backgroundColor.withValues(alpha: 0.45),
                    backgroundColor.withValues(alpha: 0.8),
                    backgroundColor.withValues(alpha: 0.9),
                    backgroundColor,
                  ],
                  stops: const [0, 0.5, 0.65, 0.85, 0.90, 0.95],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    backgroundColor.withValues(alpha: 0),
                    backgroundColor.withValues(alpha: 0.15),
                    backgroundColor.withValues(alpha: 0.65),
                    backgroundColor,
                  ],
                  stops: const [0, 0.75, 0.90, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            width: 112,
            height: 168,
            child: ContentPoster(content: content, heroTag: heroTag),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: IconButton.filled(
              tooltip: isSaved
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .70),
                foregroundColor: isSaved ? Colors.redAccent : Colors.white70,
                minimumSize: const Size(48, 48),
              ),
              icon: isSaved
                  ? Icon(HugeIconsSolid.favourite)
                  : Icon(HugeIconsStroke.favourite),
              onPressed: onFavoritePressed,
            ),
          ),
        ],
      ),
    );
  }
}
