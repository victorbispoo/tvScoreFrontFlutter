import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Decorative artwork with fixed positions, individual floating and no network fallback.
///
/// With no poster assets, labelled slots expose the composition for review.
/// Null assets leave labelled slots. The canvas scales uniformly at
/// narrow widths; compact mode shows three of the same posters on mobile.
class CinematicPosterComposition extends StatelessWidget {
  const CinematicPosterComposition({
    super.key,
    this.posterAssets = const [],
    this.posterTitles = const [],
    this.placeholderCount = 5,
    this.compact = false,
    this.collageAsset,
  }) : assert(
         posterAssets.length == 0 ||
             posterAssets.length == 4 ||
             posterAssets.length == 5,
       ),
       assert(
         posterTitles.length == 0 ||
             posterTitles.length ==
                 (posterAssets.length == 0
                     ? placeholderCount
                     : posterAssets.length),
       ),
       assert(placeholderCount == 4 || placeholderCount == 5);

  final List<String?> posterAssets;
  final List<String> posterTitles;
  final int placeholderCount;
  final bool compact;
  final String? collageAsset;

  static const backgroundColor = Color(0xFF040B17);
  static const collageBackgroundColor = Color(0xFF080B11);
  static const _canvasSize = Size(900, 620);

  // Logical poster order, independent of the fixed back-to-front paint order.
  static const _floating = [
    (amplitude: 6.0, duration: Duration(milliseconds: 5200)),
    (amplitude: 8.0, duration: Duration(milliseconds: 6100)),
    (amplitude: 7.0, duration: Duration(milliseconds: 7800)),
    (amplitude: 5.0, duration: Duration(milliseconds: 6800)),
    (amplitude: 9.0, duration: Duration(milliseconds: 5700)),
  ];

  // Required local files, not assumed to exist. The preview checks the manifest
  // before supplying any path to Image.asset. Slot 2 is the central poster.
  static const featuredPosters = [
    (title: 'Interestelar', asset: 'lib/assets/cinematic_interestellar.webp'),
    (title: 'Breaking Bad', asset: 'lib/assets/cinematic_breaking_bad.webp'),
    (
      title: 'Duna: Parte Dois',
      asset: 'lib/assets/cinematic_dune_part_two.webp',
    ),
    (
      title: 'Stranger Things',
      asset: 'lib/assets/cinematic_stranger_things.webp',
    ),
    (title: 'The Batman', asset: 'lib/assets/cinematic_the_batman.webp'),
  ];

  static const _fivePosters = [
    (poster: 0, x: 55.0, y: 300.0, width: 162.0, angle: -10.0, opacity: .90),
    (poster: 4, x: 657.0, y: 60.0, width: 166.0, angle: 9.0, opacity: .94),
    (poster: 1, x: 192.0, y: 82.0, width: 190.0, angle: -7.0, opacity: .98),
    (poster: 3, x: 557.0, y: 283.0, width: 196.0, angle: 7.0, opacity: .98),
    (poster: 2, x: 351.0, y: 165.0, width: 222.0, angle: -3.0, opacity: 1.0),
  ];
  static const _compactPosters = [
    (poster: 0, x: 110.0, y: 65.0, width: 105.0, angle: -10.0, opacity: .90),
    (poster: 3, x: 390.0, y: 35.0, width: 110.0, angle: 7.0, opacity: .98),
    (poster: 2, x: 250.0, y: 20.0, width: 130.0, angle: -3.0, opacity: 1.0),
  ];
  static const _fourPosters = [
    (poster: 0, x: 88.0, y: 268.0, width: 162.0, angle: -10.0, opacity: .76),
    (poster: 1, x: 602.0, y: 105.0, width: 176.0, angle: 10.0, opacity: .82),
    (poster: 2, x: 229.0, y: 91.0, width: 188.0, angle: -6.0, opacity: .94),
    (poster: 3, x: 395.0, y: 205.0, width: 224.0, angle: -3.0, opacity: 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    final count = posterAssets.isEmpty ? placeholderCount : posterAssets.length;
    final placements = compact
        ? _compactPosters
        : count == 4
        ? _fourPosters
        : _fivePosters;
    final canvasSize = compact ? const Size(600, 250) : _canvasSize;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: canvasSize.aspectRatio,
        child: ColoredBox(
          color: collageAsset == null
              ? backgroundColor
              : collageBackgroundColor,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox.fromSize(
                size: canvasSize,
                child: Stack(
                  children: [
                    if (collageAsset case final asset?)
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: _CollageBackground(
                            asset: asset,
                            compact: compact,
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-.05, .10),
                            radius: .90,
                            colors: [
                              AppTheme.primary.withValues(alpha: .30),
                              AppTheme.surfaceHighlight.withValues(alpha: .18),
                              AppTheme.primary.withValues(alpha: 0),
                            ],
                            stops: const [0, .42, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 450,
                      top: 25,
                      width: 400,
                      height: 440,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: .75,
                            colors: [
                              AppTheme.primary.withValues(alpha: .16),
                              AppTheme.primary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (collageAsset != null)
                      const Positioned.fill(child: _CollageEdgeFade()),
                    for (final placement in placements)
                      Positioned(
                        left: placement.x,
                        top: placement.y,
                        width: placement.width,
                        height: placement.width * 1.5,
                        child: _FloatingPoster(
                          key: ValueKey(placement.poster),
                          enabled: count == 5,
                          amplitude: _floating[placement.poster].amplitude,
                          duration: _floating[placement.poster].duration,
                          child: Transform.rotate(
                            angle: placement.angle * math.pi / 180,
                            child: Opacity(
                              opacity: placement.opacity,
                              child: _PosterFrame(
                                asset: posterAssets.isEmpty
                                    ? null
                                    : posterAssets[placement.poster],
                                title: posterTitles.isEmpty
                                    ? 'Pôster ${placement.poster + 1}'
                                    : posterTitles[placement.poster],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollageBackground extends StatelessWidget {
  const _CollageBackground({required this.asset, required this.compact});

  final String asset;
  final bool compact;

  static const _imageOpacity = .95;
  static const _overlayOpacity = .55;
  static const _blurSigma = 2.0;

  @override
  Widget build(BuildContext context) {
    const base = CinematicPosterComposition.collageBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blurSigma,
            sigmaY: _blurSigma,
            tileMode: TileMode.clamp,
          ),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            cacheWidth: compact ? 720 : 1440,
            color: Colors.white.withValues(alpha: _imageOpacity),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (_, _, _) => const SizedBox.expand(),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: _overlayOpacity),
                const Color(0xFF101827).withValues(alpha: _overlayOpacity),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CollageEdgeFade extends StatelessWidget {
  const _CollageEdgeFade();

  @override
  Widget build(BuildContext context) {
    const base = CinematicPosterComposition.collageBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                base,
                base.withValues(alpha: 0),
                base.withValues(alpha: 0),
                base,
              ],
              stops: const [0, .18, .78, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base,
                base.withValues(alpha: 0),
                base.withValues(alpha: 0),
                base,
              ],
              stops: const [0, .18, .60, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingPoster extends StatefulWidget {
  const _FloatingPoster({
    super.key,
    required this.enabled,
    required this.amplitude,
    required this.duration,
    required this.child,
  });

  final bool enabled;
  final double amplitude;
  final Duration duration;
  final Widget child;

  @override
  State<_FloatingPoster> createState() => _FloatingPosterState();
}

class _FloatingPosterState extends State<_FloatingPoster>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant _FloatingPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _updateMotion();
  }

  void _updateMotion() {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    // Image, border, shadow, opacity and fixed tilt are never rebuilt per tick.
    child: RepaintBoundary(child: widget.child),
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        -widget.amplitude * Curves.easeInOut.transform(_controller.value),
      ),
      child: child,
    ),
  );
}

class _PosterFrame extends StatelessWidget {
  const _PosterFrame({required this.asset, required this.title});

  final String? asset;
  final String title;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(9));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .65),
            blurRadius: 32,
            spreadRadius: -3,
            offset: const Offset(12, 22),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: .10),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (asset case final path?)
              Image.asset(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _PosterPlaceholder(title: title, unavailable: true),
              )
            else
              _PosterPlaceholder(title: title),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: .16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.title, this.unavailable = false});

  final String title;
  final bool unavailable;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.surfaceHighlight, AppTheme.scaffoldBackground],
      ),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_movies_outlined,
              size: 28,
              color: Colors.white.withValues(alpha: .35),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unavailable ? 'Imagem indisponível' : 'Asset local pendente',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
