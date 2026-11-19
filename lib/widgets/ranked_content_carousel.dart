import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import '../core/app_routes.dart';
import '../core/rating_scale.dart';
import '../models/content_metadata.dart';
import 'carousel_viewport.dart';
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

    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = desktop
            ? desktopRankedItemWidth(constraints.maxWidth)
            : 259.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: CarouselViewport(
            height: desktop ? 216 : 144,
            itemWidth: itemWidth,
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              final heroTag = heroTags?[index];
              return SizedBox(
                width: itemWidth,
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
                        width: desktop ? 192 : 141,
                        height: desktop ? 216 : 144,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              bottom: 5,
                              width: 54,
                              height: 48,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  (index + 1).toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              width: desktop ? 144 : 96,
                              height: desktop ? 216 : 144,
                              child: ContentPoster(
                                content: content,
                                heroTag: heroTag,
                              ),
                            ),
                          ],
                        ),
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
        );
      },
    );
  }
}
