import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class EpisodeDetailsSheet extends StatelessWidget {
  const EpisodeDetailsSheet({
    super.key,
    required this.episode,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.rating,
  });
  final Map<String, dynamic> episode;
  final int seasonNumber;
  final int episodeNumber;
  final double? rating;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .68,
    minChildSize: .48,
    maxChildSize: .9,
    expand: false,
    builder: (context, scrollController) {
      final stillPath = episode['still_path'] as String?;
      final runtime = (episode['runtime'] as num?)?.toInt();
      final votes = (episode['vote_count'] as num?)?.toInt() ?? 0;
      final airDate = episode['air_date'] as String?;
      final overview = episode['overview'] as String?;
      final hasRating = rating != null && votes > 0;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                width: double.infinity,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (stillPath != null && stillPath.isNotEmpty)
                        Image.network(
                          'https://image.tmdb.org/t/p/w780$stillPath',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _EpisodeImagePlaceholder(),
                        )
                      else
                        const _EpisodeImagePlaceholder(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                            stops: [.48, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMPORADA $seasonNumber · EPISÓDIO $episodeNumber',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      episode['name'] as String? ?? 'Episódio $episodeNumber',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _EpisodeMeta(
                          icon: HugeIconsSolid.star,
                          label: hasRating
                              ? 'TMDB ${rating!.toStringAsFixed(1)}'
                              : 'Sem avaliações',
                        ),
                        if (hasRating)
                          _EpisodeMeta(
                            icon: Icons.people_outline,
                            label: '$votes votos',
                          ),
                        if (airDate != null && airDate.isNotEmpty)
                          _EpisodeMeta(
                            icon: Icons.calendar_today_outlined,
                            label: airDate,
                          ),
                        if (runtime != null && runtime > 0)
                          _EpisodeMeta(
                            icon: Icons.schedule,
                            label: '$runtime min',
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Sinopse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      overview == null || overview.trim().isEmpty
                          ? 'Sinopse indisponível'
                          : overview,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _EpisodeImagePlaceholder extends StatelessWidget {
  const _EpisodeImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: Center(
      child: Icon(
        Icons.movie_outlined,
        size: 42,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _EpisodeMeta extends StatelessWidget {
  const _EpisodeMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 15,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    ],
  );
}
