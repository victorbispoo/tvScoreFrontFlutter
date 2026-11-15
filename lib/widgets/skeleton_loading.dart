import 'package:flutter/material.dart';

import '../core/app_theme.dart';

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
                    colors: const [
                      AppTheme.surface,
                      AppTheme.surfaceHighlight,
                      AppTheme.surface,
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
      color: AppTheme.surfaceHighlight.withValues(alpha: .55),
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
  });

  final bool featured;
  final bool showHeading;
  final bool showFilters;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
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
          SizedBox(
            height: featured ? 318 : 284,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => SizedBox(
                width: featured ? 158 : 144,
                child: const SkeletonPosterCard(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SkeletonRankedCarousel extends StatelessWidget {
  const SkeletonRankedCarousel({super.key});

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: SizedBox(
        height: 144,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, _) => const SizedBox(
            width: 248,
            child: Row(
              children: [
                SkeletonBlock(width: 25, height: 24),
                SizedBox(width: 5),
                SkeletonBlock(width: 100, height: 144),
                SizedBox(width: 10),
                Expanded(
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
    ),
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
      itemCount: 6,
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
