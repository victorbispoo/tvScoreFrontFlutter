import 'package:flutter/material.dart';

class EpisodeRatingsGrid extends StatefulWidget {
  const EpisodeRatingsGrid({super.key, required this.seasons});

  final List<Map<String, dynamic>> seasons;

  @override
  State<EpisodeRatingsGrid> createState() => _EpisodeRatingsGridState();
}

class _EpisodeRatingsGridState extends State<EpisodeRatingsGrid> {
  int? _selectedSeasonNumber;

  Color _ratingColor(double? rating) {
    if (rating == null) {
      return const Color(0xFF64748B);
    }

    final value = rating.clamp(0.0, 10.0).toDouble();
    if (value >= 9.5) {
      return const Color(0xFF8B3DFF);
    }
    const stops = <(double, Color)>[
      (0.0, Color(0xFFC21842)),
      (3.0, Color(0xFFDF4936)),
      (5.0, Color(0xFFE87513)),
      (6.0, Color(0xFFC29B00)),
      (7.0, Color(0xFF79A500)),
      (7.5, Color(0xFF24A66A)),
      (8.0, Color(0xFF009BBD)),
      (8.5, Color(0xFF246BDD)),
      (9.5, Color(0xFF3654C7)),
    ];

    for (int i = 0; i < stops.length - 1; i++) {
      final (start, startColor) = stops[i];
      final (end, endColor) = stops[i + 1];

      if (value <= end) {
        final t = (value - start) / (end - start);

        return Color.lerp(startColor, endColor, t)!;
      }
    }

    return stops.last.$2;
  }

  Widget _buildCell(
    Map<String, dynamic> episode,
    int seasonNumber,
    int episodeNumber,
  ) {
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

    return Semantics(
      label:
          'Temporada $seasonNumber, episódio $episodeNumber: '
          '${rating?.toStringAsFixed(1) ?? 'sem nota'}',
      child: ExcludeSemantics(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ratingColor(rating),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'E$episodeNumber',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                rating?.toStringAsFixed(1) ?? '—',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasons = widget.seasons.toList()
      ..sort(
        (a, b) =>
            (a['season_number'] as num).compareTo(b['season_number'] as num),
      );

    if (seasons.isEmpty) {
      return const Text('Episódios não disponíveis');
    }

    final selectedSeason = seasons.firstWhere(
      (season) => season['season_number'] == _selectedSeasonNumber,
      orElse: () => seasons.firstWhere(
        (season) => (season['season_number'] as num).toInt() > 0,
        orElse: () => seasons.first,
      ),
    );
    final seasonNumber = (selectedSeason['season_number'] as num).toInt();
    final episodes =
        (selectedSeason['episodes'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
          ..sort(
            (a, b) => (a['episode_number'] as num).compareTo(
              b['episode_number'] as num,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notas dos episódios',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          key: ValueKey(seasonNumber),
          initialValue: seasonNumber,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Temporada',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final season in seasons)
              DropdownMenuItem(
                value: (season['season_number'] as num).toInt(),
                child: Text(
                  season['season_number'] == 0
                      ? 'Especiais'
                      : 'Temporada ${season['season_number']}',
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedSeasonNumber = value),
        ),
        const SizedBox(height: 12),
        Text(
          '${episodes.length} ${episodes.length == 1 ? 'episódio' : 'episódios'} • Notas TMDB',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (episodes.isEmpty)
          const Text('Episódios não disponíveis nesta temporada')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final columns = ((constraints.maxWidth + spacing) / 68)
                  .floor()
                  .clamp(1, 8);
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final episode in episodes)
                    SizedBox(
                      width: width,
                      height: 64,
                      child: _buildCell(
                        episode,
                        seasonNumber,
                        (episode['episode_number'] as num).toInt(),
                      ),
                    ),
                ],
              );
            },
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
