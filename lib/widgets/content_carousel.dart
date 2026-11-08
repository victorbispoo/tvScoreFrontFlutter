import 'package:flutter/material.dart';

import 'content_card.dart';

class ContentCarousel extends StatelessWidget {
  const ContentCarousel({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.contents,
    required this.onChanged,
  });

  final Icon? icon;
  final String title;
  final String? subtitle;
  final List<Map<String, String>> contents;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final subtitle = this.subtitle;
    if (contents.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: contents.length,
              separatorBuilder: (_, index) => const SizedBox(width: 14),
              itemBuilder: (_, index) => SizedBox(
                width: 160,
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
