import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import 'ranked_content_carousel.dart';
import 'skeleton_loading.dart';
import 'tv_score_segmented_control.dart';

class TopRatedCarousel extends StatelessWidget {
  const TopRatedCarousel({
    super.key,
    required this.contents,
    required this.selectedType,
    required this.onTypeSelected,
    required this.onRetry,
    required this.onChanged,
    this.heroSection,
  });

  final Future<List<Map<String, String>>> contents;
  final VoidCallback onChanged;
  final String? heroSection;
  final String selectedType;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(
              HugeIconsSolid.star,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Mais bem avaliados',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
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
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, String>>>(
        future: contents,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SkeletonRankedCarousel();
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Não foi possível carregar. Tentar novamente',
                ),
              ),
            );
          }
          final contents = snapshot.data!;
          if (contents.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Nenhum t\u00edtulo nesta categoria.'),
            );
          }
          return RankedContentCarousel(
            contents: contents,
            onChanged: onChanged,
            heroSection: heroSection,
          );
        },
      ),
    ],
  );
}
