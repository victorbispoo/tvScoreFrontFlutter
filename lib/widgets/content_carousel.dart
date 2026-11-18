import 'package:flutter/material.dart';

import 'content_card.dart';
import 'poster_hero_tag.dart';

class ContentCarousel extends StatelessWidget {
  const ContentCarousel({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.featured = false,
    this.showHeading = true,
    required this.contents,
    required this.onChanged,
    this.heroSection,
    this.posterScale = 1,
    this.filters,
  });

  final Icon? icon;
  final String title;
  final String? subtitle;
  final bool featured;
  final bool showHeading;
  final List<Map<String, String>> contents;
  final VoidCallback onChanged;
  final String? heroSection;
  final double posterScale;
  final Widget? filters;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final subtitle = this.subtitle;
    if (contents.isEmpty && filters == null) return const SizedBox.shrink();
    final basePosterWidth = featured ? 158.0 : 144.0;
    final posterWidth = basePosterWidth * posterScale;
    final height =
        (featured ? 318.0 : 284.0) + (posterWidth - basePosterWidth) * 1.5;
    final heroTags = heroSection == null
        ? null
        : carouselPosterHeroTags('home:$heroSection', contents);
    return Padding(
      padding: EdgeInsets.only(
        bottom: Theme.of(context).brightness == Brightness.light ? 18 : 26,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[icon, const SizedBox(width: 8)],
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: (featured ? 23 : 19) * posterScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (showHeading) const SizedBox(height: 14),
          if (filters != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: filters!,
            ),
            const SizedBox(height: 10),
          ],
          if (contents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Nenhum título nesta categoria.'),
            )
          else
            SizedBox(
              height: height,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: contents.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (_, index) => SizedBox(
                  width: posterWidth,
                  child: ContentCard(
                    content: contents[index],
                    textScale: posterScale,
                    onChanged: onChanged,
                    heroTag: heroTags?[index],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
