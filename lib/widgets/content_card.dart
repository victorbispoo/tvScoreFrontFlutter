import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_routes.dart';
import '../core/rating_scale.dart';
import '../models/content_metadata.dart';
import 'content_poster.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.content,
    this.onChanged,
    this.onFavoriteChanged,
    this.heroTag,
  });

  final VoidCallback? onChanged;
  final VoidCallback? onFavoriteChanged;
  final Map<String, String> content;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await AppRoutes.openDetails(
          context,
          content: content,
          heroTag: heroTag,
          onFavoriteChanged: onFavoriteChanged,
        );
        if (context.mounted) onChanged?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentPoster(content: content, heroTag: heroTag),
                if ((double.tryParse(content['score'] ?? '') ?? 0) > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            HugeIconsSolid.star,
                            color: RatingScale.badgeColor(
                              context,
                              double.tryParse(content['score'] ?? ''),
                            ),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content['score'] ?? '—',
                            style: TextStyle(
                              color: RatingScale.badgeColor(
                                context,
                                double.tryParse(content['score'] ?? ''),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 40,
            child: Text(
              content['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${content['year']} • ${content.primaryGenre}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
