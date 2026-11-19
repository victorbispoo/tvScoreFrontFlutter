import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tv_score_front_flutter/core/app_theme.dart';
import 'package:tv_score_front_flutter/widgets/cinematic_poster_composition.dart';

// Isolated entry point: no routes, session restoration, API or auth pages.
void main() => runApp(const CinematicGlowPreview());

class CinematicGlowPreview extends StatefulWidget {
  const CinematicGlowPreview({super.key});

  @override
  State<CinematicGlowPreview> createState() => _CinematicGlowPreviewState();
}

class _CinematicGlowPreviewState extends State<CinematicGlowPreview> {
  late final Future<Set<String>> _availableAssets =
      AssetManifest.loadFromAssetBundle(
        rootBundle,
      ).then((manifest) => manifest.listAssets().toSet());

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TVScore · Cinematic Glow',
    theme: AppTheme.dark,
    home: FutureBuilder<Set<String>>(
      future: _availableAssets,
      builder: (context, snapshot) {
        final available = snapshot.data ?? const <String>{};
        final posters = CinematicPosterComposition.featuredPosters;
        final missing = posters.where(
          (poster) => !available.contains(poster.asset),
        );
        return Scaffold(
          backgroundColor: CinematicPosterComposition.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'TVScore · Cinematic Glow',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cinematic Glow · Flutuação individual dos pôsteres',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '5 pôsteres fixos · Duna: Parte Dois em destaque',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      CinematicPosterComposition(
                        posterAssets: [
                          for (final poster in posters)
                            available.contains(poster.asset)
                                ? poster.asset
                                : null,
                        ],
                        posterTitles: [
                          for (final poster in posters) poster.title,
                        ],
                      ),
                      if (snapshot.connectionState != ConnectionState.done)
                        const Text(
                          'Verificando assets locais…',
                          style: TextStyle(color: Colors.white54),
                        )
                      else if (missing.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Assets locais pendentes · WebP 2:3, recomendado 600 × 900 px',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        for (final poster in missing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${poster.title}: ${poster.asset}',
                              style: const TextStyle(
                                color: Colors.white54,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
