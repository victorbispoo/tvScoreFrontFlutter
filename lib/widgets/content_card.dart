import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../pages/details_page.dart';

class ContentPoster extends StatelessWidget {
  const ContentPoster({super.key, required this.content});

  final Map<String, String> content;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      content['poster_path'] ?? '',
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppTheme.surfaceHighlight,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (_, error, stack) => const ColoredBox(
        color: AppTheme.surfaceHighlight,
        child: Center(
          child: Icon(Icons.movie_outlined, size: 42, color: Colors.white54),
        ),
      ),
    ),
  );
}

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.content, this.onChanged});

  final VoidCallback? onChanged;
  final Map<String, String> content;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsPage(content: content)),
        );
        if (context.mounted) onChanged?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentPoster(content: content),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(content['score'] ?? '—'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content['title'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '${content['year']} • ${content['genre']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
