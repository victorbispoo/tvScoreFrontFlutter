import 'package:flutter/material.dart';

class EpisodeRatingsGrid extends StatelessWidget {
  const EpisodeRatingsGrid({super.key, required this.seasons});

  final List<Map<String, dynamic>> seasons;

  Color _ratingColor(double? rating) {
    if (rating == null) {
      return const Color(0xFF64748B);
    }

    final value = rating.clamp(0.0, 10.0).toDouble();

    // Cor exclusiva para obras-primas
    if (value >= 9.5) {
      return const Color(0xFF8B3DFF);
    }

    // Pontos de referência do gradiente
    const stops = <(double, Color)>[
      (0.0, Color(0xFFC62845)),
      (3.0, Color(0xFFDC4934)),
      (5.0, Color(0xFFD97706)),
      (6.0, Color(0xFFB59B00)),
      (7.0, Color(0xFF77A519)),
      (8.0, Color(0xFF24A366)),
      (9.5, Color(0xFF008F76)),
    ];

    for (int i = 0; i < stops.length - 1; i++) {
      final (startValue, startColor) = stops[i];
      final (endValue, endColor) = stops[i + 1];

      if (value <= endValue) {
        final t = (value - startValue) / (endValue - startValue);

        return Color.lerp(startColor, endColor, t)!;
      }
    }

    return stops.last.$2;
  }

  Widget _buildCell(
    Map<String, dynamic>? episode,
    int seasonNumber,
    int episodeNumber,
  ) {
    if (episode == null) return const SizedBox(height: 52);

    final votes = (episode['vote_count'] as num?)?.toInt() ?? 0;
    final value = (episode['vote_average'] as num?)?.toDouble();
    final rating =
        votes > 0 &&
            value != null &&
            value.isFinite &&
            value >= 0 &&
            value <= 10
        ? value
        : null;

    return Container(
      height: 44,
      margin: const EdgeInsets.all(4),
      alignment: .center,
      decoration: BoxDecoration(
        color: _ratingColor(rating),
        borderRadius: .circular(8),
      ),
      child: Text(
        rating?.toStringAsFixed(1) ?? '-',
        style: const TextStyle(color: Colors.white, fontWeight: .bold),
        semanticsLabel:
            'Temporada $seasonNumber, episódio $episodeNumber: '
            '${rating?.toStringAsFixed(1) ?? 'sem nota'}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodesBySeason = seasons.map((season) {
      final episodes = season['episodes'] as List? ?? [];

      return <int, Map<String, dynamic>>{
        for (final item in episodes)
          (item['episode_number'] as num).toInt(): Map<String, dynamic>.from(
            item as Map,
          ),
      };
    }).toList();

    final episodeNumbers =
        episodesBySeason.expand((episodes) => episodes.keys).toSet().toList()
          ..sort();

    if (episodeNumbers.isEmpty) {
      return const Text('Episódios não disponíveis');
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        const Text(
          'Notas dos episódios',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(64),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  const SizedBox(height: 36),
                  for (final season in seasons)
                    Center(child: Text('T${season['season_number']}')),
                ],
              ),
              for (final number in episodeNumbers)
                TableRow(
                  children: [
                    Text(
                      'E$number',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    for (var index = 0; index < seasons.length; index++)
                      _buildCell(
                        episodesBySeason[index][number],
                        (seasons[index]['season_number'] as num).toInt(),
                        number,
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            for (final item in [
              (9.5, 'Obra-prima'),
              (9.0, 'Excepcional'),
              (8.0, 'Excelente'),
              (7.0, 'Muito bom'),
              (6.0, 'Bom'),
              (5.0, 'Regular'),
              (3.0, 'Fraco'),
              (0.0, 'Horrível'),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _ratingColor(item.$1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.$2, style: const TextStyle(fontSize: 12)),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _ratingColor(null),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Sem nota', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
