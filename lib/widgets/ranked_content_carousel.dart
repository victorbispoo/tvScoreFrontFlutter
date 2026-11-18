import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_routes.dart';
import '../core/rating_scale.dart';
import '../models/content_metadata.dart';
import 'content_poster.dart';
import 'poster_hero_tag.dart';

class RankedContentCarousel extends StatelessWidget {
  const RankedContentCarousel({
    super.key,
    required this.contents,
    required this.onChanged,
    this.heroSection,
  });

  final List<Map<String, String>> contents;
  final VoidCallback onChanged;
  final String? heroSection;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) return const SizedBox.shrink();
    final heroTags = heroSection == null
        ? null
        : carouselPosterHeroTags('home:$heroSection', contents);

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: SizedBox(
        height: 144,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: contents.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final content = contents[index];
            final heroTag = heroTags?[index];
            return SizedBox(
              width: 248,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await AppRoutes.openDetails(
                    context,
                    content: content,
                    heroTag: heroTag,
                  );
                  if (context.mounted) onChanged();
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 150,
                      child: ContentPoster(content: content, heroTag: heroTag),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            content['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${content['year'] ?? ''} · ${content.primaryGenre}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if ((double.tryParse(content['score'] ?? '') ?? 0) >
                              0) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  HugeIconsSolid.star,
                                  size: 20,
                                  color: RatingScale.badgeColor(
                                    context,
                                    double.tryParse(content['score'] ?? ''),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${content['score']}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: RatingScale.badgeColor(
                                      context,
                                      double.tryParse(content['score'] ?? ''),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              'Sem avaliações',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
