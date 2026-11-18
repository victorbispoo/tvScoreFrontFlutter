import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import 'content_carousel.dart';
import 'tv_score_segmented_control.dart';

class TrendingCarousel extends StatefulWidget {
  const TrendingCarousel({
    super.key,
    required this.contents,
    required this.onChanged,
    this.heroSection,
  });

  final List<Map<String, String>> contents;
  final VoidCallback onChanged;
  final String? heroSection;

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  String _filter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final contents = widget.contents.where((content) {
      return _filter == 'ALL' || content['type'] == _filter;
    }).toList();

    if (widget.contents.isEmpty) return const SizedBox.shrink();

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
              selectedValue: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
          ),
          const SizedBox(height: 10),
          ContentCarousel(
            title: '',
            contents: contents,
            onChanged: widget.onChanged,
            heroSection: widget.heroSection,
            showHeading: false,
          ),
        ],
      ),
    );
  }
}
