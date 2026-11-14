import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_theme.dart';
import '../services/api_services.dart';
import 'ranked_content_carousel.dart';

class TopRatedCarousel extends StatefulWidget {
  const TopRatedCarousel({
    super.key,
    required this.contents,
    required this.onChanged,
  });

  final Future<List<Map<String, String>>> contents;
  final VoidCallback onChanged;

  @override
  State<TopRatedCarousel> createState() => _TopRatedCarouselState();
}

class _TopRatedCarouselState extends State<TopRatedCarousel> {
  int _minimumRating = 7;
  late Future<List<Map<String, String>>> _contents;

  @override
  void initState() {
    super.initState();
    _contents = widget.contents;
  }

  void _loadContents() {
    _contents = ApiService().getTopRatedMovies(_minimumRating);
  }

  void _selectMinimum(int minimum) {
    setState(() {
      _minimumRating = minimum;
      _loadContents();
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(HugeIconsSolid.star, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Mais bem avaliados',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 8,
          children: [
            for (final minimum in [7, 8, 9])
              ChoiceChip(
                label: Text('$minimum+'),
                selected: _minimumRating == minimum,
                onSelected: (_) => _selectMinimum(minimum),
              ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<Map<String, String>>>(
        future: _contents,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) {
            return const SizedBox(
              height: 144,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextButton(
                onPressed: () => setState(_loadContents),
                child: const Text('Não foi possível carregar. Tentar novamente'),
              ),
            );
          }
          final contents = snapshot.data!;
          if (contents.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Nenhum filme nesta faixa de nota.'),
            );
          }
          return RankedContentCarousel(
            contents: contents,
            onChanged: widget.onChanged,
          );
        },
      ),
    ],
  );
}
