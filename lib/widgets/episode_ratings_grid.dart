import 'package:flutter/material.dart';
import '../core/rating_scale.dart';
import 'episode_details_sheet.dart';
import 'season_selector.dart';

class EpisodeRatingsGrid extends StatefulWidget {
  const EpisodeRatingsGrid({super.key, required this.seasons});

  final List<Map<String, dynamic>> seasons;

  @override
  State<EpisodeRatingsGrid> createState() => _EpisodeRatingsGridState();
}

class _EpisodeRatingsGridState extends State<EpisodeRatingsGrid> {
  int? _selectedSeasonNumber;

  Widget _buildCell(
    Map<String, dynamic> episode,
    int seasonNumber,
    int episodeNumber,
  ) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.light
        ? Colors.white
        : theme.colorScheme.onSurface;
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
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              _showEpisode(episode, seasonNumber, episodeNumber, rating),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RatingScale.color(rating),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'E$episodeNumber',
                  style: TextStyle(color: textColor, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  rating?.toStringAsFixed(1) ?? '—',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEpisode(
    Map<String, dynamic> episode,
    int seasonNumber,
    int episodeNumber,
    double? rating,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EpisodeDetailsSheet(
      episode: episode,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      rating: rating,
    ),
  );
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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Notas dos episódios',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            SeasonSelector(
              seasons: seasons
                  .map((season) => (season['season_number'] as num).toInt())
                  .toList(),
              value: seasonNumber,
              onChanged: (value) =>
                  setState(() => _selectedSeasonNumber = value),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${episodes.length} ${episodes.length == 1 ? 'episódio' : 'episódios'} • Notas TMDB',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
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
            for (final item in RatingScale.bands)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: RatingScale.color(item.$1),
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
                    color: RatingScale.color(null),
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
