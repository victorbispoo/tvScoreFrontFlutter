import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';

import '../core/rating_scale.dart';
import '../models/content_metadata.dart';
import '../pages/details_page.dart';
import 'content_poster.dart';

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
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentPoster(content: content),
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
                        color: AppTheme.scaffoldBackground.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.surfaceHighlight, width: 0.5)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            HugeIconsSolid.star,
                            color: RatingScale.color(
                              double.tryParse(content['score'] ?? ''),
                            ),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content['score'] ?? '—',
                            style: TextStyle(
                              color: RatingScale.color(
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
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
