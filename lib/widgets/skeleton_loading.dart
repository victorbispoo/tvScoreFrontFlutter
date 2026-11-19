import 'package:flutter/material.dart';

import '../core/app_breakpoints.dart';
import 'carousel_viewport.dart';

class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _animation.stop();
    } else if (!_animation.isAnimating) {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Carregando conteúdo',
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: MediaQuery.disableAnimationsOf(context)
            ? widget.child
            : AnimatedBuilder(
                animation: _animation,
                child: widget.child,
                builder: (context, child) => ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(-2 + _animation.value * 4, 0),
                    end: Alignment(-1 + _animation.value * 4, 0),
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
              ),
      ),
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class SkeletonPosterCard extends StatelessWidget {
  const SkeletonPosterCard({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      AspectRatio(aspectRatio: 2 / 3, child: SkeletonBlock()),
      SizedBox(height: 7),
      SkeletonBlock(height: 15),
      SizedBox(height: 8),
      FractionallySizedBox(widthFactor: .65, child: SkeletonBlock(height: 11)),
    ],
  );
}

class SkeletonCarousel extends StatelessWidget {
  const SkeletonCarousel({
    super.key,
    this.featured = false,
    this.showHeading = true,
    this.showFilters = false,
    this.posterScale = 1,
  });

  final bool featured;
  final bool showHeading;
  final bool showFilters;
  final double posterScale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = MediaQuery.sizeOf(context).width;
      final desktop = AppBreakpoints.isDesktop(viewport);
      final baseWidth = featured ? 158.0 : 144.0;
      final posterWidth = desktop
          ? desktopCarouselPosterWidth(constraints.maxWidth, featured: featured)
          : baseWidth * posterScale;
      return SkeletonShimmer(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: desktop && Theme.of(context).brightness == Brightness.light
                ? 18
                : 26,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SkeletonBlock(width: 155, height: 22),
                ),
                const SizedBox(height: 14),
              ],
              if (showFilters) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: desktop
                      ? const SkeletonBlock(width: 336, height: 48, radius: 24)
                      : featured
                      ? const SkeletonBlock(height: 36, radius: 18)
                      : const Row(
                          children: [
                            SkeletonBlock(width: 76, height: 36, radius: 18),
                            SizedBox(width: 8),
                            SkeletonBlock(width: 76, height: 36, radius: 18),
                            SizedBox(width: 8),
                            SkeletonBlock(width: 76, height: 36, radius: 18),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
              ],
              if (desktop) const SizedBox(height: 48),
              SizedBox(
                height: desktop
                    ? posterWidth * 1.5 + 84
                    : (featured ? 318 : 284) + (posterWidth - baseWidth) * 1.5,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: viewport >= AppBreakpoints.tablet
                      ? (constraints.maxWidth / (posterWidth + 12)).ceil()
                      : 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, _) => SizedBox(
                    width: posterWidth,
                    child: const SkeletonPosterCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SkeletonRankedCarousel extends StatelessWidget {
  const SkeletonRankedCarousel({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = AppBreakpoints.isDesktop(
        MediaQuery.sizeOf(context).width,
      );
      final width = desktop
          ? desktopRankedItemWidth(constraints.maxWidth)
          : 248.0;
      final height = desktop ? 216.0 : 144.0;
      return SkeletonShimmer(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            children: [
              if (desktop) const SizedBox(height: 48),
              SizedBox(
                height: height,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: desktop
                      ? (constraints.maxWidth / (width + 12)).ceil()
                      : 3,
                  separatorBuilder: (_, _) => SizedBox(width: 12),
                  itemBuilder: (_, _) => SizedBox(
                    width: width,
                    child: Row(
                      children: [
                        SkeletonBlock(width: desktop ? 43 : 25, height: 24),
                        const SizedBox(width: 5),
                        SkeletonBlock(width: height * 2 / 3, height: height),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SkeletonBlock(height: 16),
                              SizedBox(height: 9),
                              SkeletonBlock(height: 12),
                              SizedBox(height: 9),
                              SkeletonBlock(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    required this.columns,
    required this.mainAxisExtent,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
  });

  final int columns;
  final double mainAxisExtent;
  final bool shrinkWrap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    child: GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: padding,
      itemCount: columns > 3 ? columns * 2 : 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: 14,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (_, _) => const SkeletonPosterCard(),
    ),
  );
}
