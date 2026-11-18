import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import 'content_carousel.dart';
import 'tv_score_segmented_control.dart';

class TrendingCarousel extends StatelessWidget {
  const TrendingCarousel({
    super.key,
    required this.contents,
    required this.onChanged,
    required this.selectedType,
    required this.onTypeSelected,
    this.showWhenEmpty = false,
    this.heroSection,
  });

  final List<Map<String, String>> contents;
  final VoidCallback onChanged;
  final String? heroSection;

  final String selectedType;
  final ValueChanged<String> onTypeSelected;
  final bool showWhenEmpty;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty && !showWhenEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  HugeIconsSolid.fire,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Em alta',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TvScoreSegmentedControl<String>(
              options: const {
                'ALL': 'Todos',
                'MOVIE': 'Filmes',
                'TV': 'S\u00e9ries',
              },
              selectedValue: selectedType,
              onChanged: onTypeSelected,
            ),
          ),
          const SizedBox(height: 10),
          ContentCarousel(
            title: '',
            contents: contents,
            onChanged: onChanged,
            heroSection: heroSection,
            showHeading: false,
          ),
        ],
      ),
    );
  }
}
