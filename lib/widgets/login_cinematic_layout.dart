import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_breakpoints.dart';
import '../core/light_logo_color_mapper.dart';
import 'cinematic_poster_composition.dart';

class LoginCinematicLayout extends StatelessWidget {
  const LoginCinematicLayout({super.key, required this.child});

  final Widget child;

  Widget _posters({bool compact = false}) => CinematicPosterComposition(
    compact: compact,
    posterAssets: [
      for (final poster in CinematicPosterComposition.featuredPosters)
        poster.asset,
    ],
    posterTitles: [
      for (final poster in CinematicPosterComposition.featuredPosters)
        poster.title,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: BackdropGroup(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktop =
                  AppBreakpoints.supportsWidePages &&
                  AppBreakpoints.isDesktop(constraints.maxWidth);
              final form = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: 144,
                      height: 96,
                      child: SvgPicture.asset(
                        'lib/assets/tvScoreLogin.svg',
                        colorMapper: theme.brightness == Brightness.light
                            ? const LightLogoColorMapper()
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  child,
                ],
              );
              final formArea = Padding(
                padding: EdgeInsets.all(desktop ? 32 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: desktop
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.surface.withValues(alpha: .88),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: .16,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: form,
                                ),
                              ),
                            ),
                          )
                        : form,
                  ),
                ),
              );
              if (!desktop) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: (constraints.maxWidth / 2.4).clamp(
                          120.0,
                          170.0,
                        ),
                        child: _posters(compact: true),
                      ),
                      formArea,
                    ],
                  ),
                );
              }
              return Row(
                children: [
                  Expanded(
                    flex: 55,
                    child: ColoredBox(
                      color: CinematicPosterComposition.backgroundColor,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _posters(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                child: Text(
                                  'Toda história merece ser descoberta.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -.5,
                                      ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Explore. Avalie. Descubra.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 45,
                    child: Center(
                      child: SingleChildScrollView(child: formArea),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
