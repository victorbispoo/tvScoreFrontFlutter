import 'package:flutter/material.dart';

import 'content_card.dart';

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
  });

  final Icon? icon;
  final String title;
  final String? subtitle;
  final bool featured;
  final bool showHeading;
  final List<Map<String, String>> contents;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final subtitle = this.subtitle;
    if (contents.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
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
                            fontSize: featured ? 23 : 19,
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
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ],
              ),
            ),
          if (showHeading) const SizedBox(height: 14),
          SizedBox(
            height: featured ? 318 : 284,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: contents.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: featured ? 158 : 144,
                child: ContentCard(
                  content: contents[index],
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
