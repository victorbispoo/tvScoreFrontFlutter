import 'package:flutter/material.dart';

import 'content_card.dart';

class ContentHeader extends StatelessWidget {
  const ContentHeader({super.key, required this.content});

  final Map<String, String> content;

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
              fit: BoxFit.fitHeight,
              alignment: const Alignment(0.3, 0),
              errorBuilder: (_, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, size: 48)),
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
            width: 125,
            height: 170,
            child: ContentPoster(content: content),
          ),
        ],
      ),
    );
  }
}
