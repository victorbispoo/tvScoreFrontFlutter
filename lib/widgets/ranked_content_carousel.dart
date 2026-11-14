import 'package:flutter/material.dart';

import '../models/content_metadata.dart';
import '../pages/details_page.dart';
import 'content_poster.dart';

class RankedContentCarousel extends StatelessWidget {
  const RankedContentCarousel({
    super.key,
    required this.contents,
    required this.onChanged,
  });

  final List<Map<String, String>> contents;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (contents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: SizedBox(
        height: 144,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: contents.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final content = contents[index];
            return SizedBox(
              width: 248,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(content: content),
                    ),
                  );
                  if (context.mounted) onChanged();
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 66,
                      height: 99,
                      child: ContentPoster(content: content),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            content['title'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${content['year'] ?? ''} · ${content.primaryGenre}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                          if ((double.tryParse(content['score'] ?? '') ?? 0) >
                              0) ...[
                            const SizedBox(height: 5),
                            Text(
                              'TMDB ${content['score']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else
                            const Text(
                              'Sem avaliações',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
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
        ),
      ),
    );
  }
}
