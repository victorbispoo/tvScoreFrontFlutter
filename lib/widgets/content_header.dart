import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';
import 'content_poster.dart';
import 'skeleton_loading.dart';

class ContentHeader extends StatelessWidget {
  const ContentHeader({
    super.key,
    required this.content,
    required this.onFavoritePressed,
    required this.isSaved,
    this.heroTag,
    required this.information,
  });

  final Map<String, String> content;
  final VoidCallback? onFavoritePressed;
  final bool isSaved;
  final Object? heroTag;
  final Widget information;

  static List<Gradient> backdropGradients(Color backgroundColor) => [
    if (ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark)
      LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          backgroundColor.withValues(alpha: 0.05),
          backgroundColor.withValues(alpha: 0.15),
          backgroundColor.withValues(alpha: 0.45),
          backgroundColor.withValues(alpha: 0.8),
          backgroundColor.withValues(alpha: 0.9),
          backgroundColor,
        ],
        stops: const [0, 0.5, 0.65, 0.85, 0.90, 0.95],
      ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        backgroundColor.withValues(alpha: 0),
        backgroundColor.withValues(alpha: 0.15),
        backgroundColor.withValues(alpha: 0.65),
        backgroundColor,
      ],
      stops:
          ThemeData.estimateBrightnessForColor(backgroundColor) ==
              Brightness.light
          ? const [0, .82, .94, 1]
          : const [0, .75, .90, 1],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final backdrop = content['backdrop_path'];
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final desktop =
            AppBreakpoints.supportsWidePages && AppBreakpoints.isDesktop(width);
        final tablet =
            AppBreakpoints.supportsWidePages && width >= AppBreakpoints.tablet;
        final inset = tablet ? (width * .03).clamp(24.0, 48.0) : 0.0;
        final contentWidth = (width - 2 * inset).clamp(0.0, 1280.0);
        final gap = (width * .03).clamp(24.0, 48.0);
        final posterWidth = desktop
            ? (contentWidth * .34).clamp(300.0, 420.0)
            : tablet
            ? (contentWidth * .33).clamp(180.0, 280.0)
            : 112.0;
        final top = MediaQuery.paddingOf(context).top;
        final posterArea = tablet ? posterWidth * 1.5 : 350 + top;
        final backdropHeight = desktop
            ? (posterArea + 92).clamp(600.0, 700.0)
            : tablet
            ? posterArea + 96
            : posterArea;
        return Stack(
          children: [
            if (tablet) SizedBox(height: backdropHeight),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: backdropHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    backdrop ?? '',
                    fit: BoxFit.cover,
                    alignment: tablet
                        ? const Alignment(0, -.2)
                        : const Alignment(.3, 0),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SkeletonBlock(radius: 0),
                    errorBuilder: (_, error, stackTrace) => Center(
                      child: Icon(
                        HugeIconsStroke.film01,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (tablet)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            backgroundColor.withValues(alpha: .58),
                            backgroundColor.withValues(alpha: .20),
                            backgroundColor.withValues(alpha: .94),
                            backgroundColor,
                          ],
                          stops: const [0, .22, .37, 1],
                        ),
                      ),
                    ),
                  for (final gradient
                      in tablet
                          ? [backdropGradients(backgroundColor).last]
                          : backdropGradients(backgroundColor))
                    DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  tablet ? top + kToolbarHeight + 16 : 0,
                  inset,
                  tablet ? 16 : 0,
                ),
                child: SizedBox(
                  width: contentWidth,
                  child: Wrap(
                    spacing: gap,
                    children: [
                      SizedBox(
                        width: tablet ? posterWidth : contentWidth,
                        height: posterArea,
                        child: Stack(
                          children: [
                            Positioned(
                              left: tablet ? 0 : 20,
                              bottom: tablet ? 0 : 20,
                              width: posterWidth,
                              height: posterWidth * 1.5,
                              child: ContentPoster(
                                content: content,
                                heroTag: heroTag,
                              ),
                            ),
                            Positioned(
                              right: tablet ? 12 : 20,
                              bottom: tablet ? 12 : 20,
                              child: IconButton.filled(
                                tooltip: isSaved
                                    ? 'Remover dos favoritos'
                                    : 'Adicionar aos favoritos',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Theme.of(context).colorScheme.surface
                                      : Colors.black.withValues(alpha: .70),
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? (isSaved
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.error
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface)
                                      : (isSaved
                                            ? Colors.redAccent
                                            : Colors.white70),
                                  minimumSize: const Size(48, 48),
                                ),
                                icon: isSaved
                                    ? Icon(HugeIconsSolid.favourite)
                                    : Icon(HugeIconsStroke.favourite),
                                onPressed: onFavoritePressed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: tablet
                            ? (contentWidth - posterWidth - gap).clamp(
                                0.0,
                                desktop && content['type'] == 'TV'
                                    ? double.infinity
                                    : 640.0,
                              )
                            : contentWidth,
                        child: Padding(
                          padding: tablet
                              ? const EdgeInsets.only(top: 16)
                              : const EdgeInsets.symmetric(horizontal: 20),
                          child: information,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
