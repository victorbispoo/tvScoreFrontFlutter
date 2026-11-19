import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_breakpoints.dart';
import '../core/light_logo_color_mapper.dart';

class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({super.key, this.logoSpacing, required this.child});

  // A null spacing keeps the existing compact registration layout.
  final double? logoSpacing;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          AppBreakpoints.supportsWidePages &&
          constraints.maxWidth >= AppBreakpoints.tablet;
      final split = wide && AppBreakpoints.isDesktop(constraints.maxWidth);
      final formWidth = constraints.maxWidth.clamp(0.0, wide ? 440.0 : 420.0);
      return Center(
        child: SizedBox(
          width: split ? 260 + 64 + formWidth : formWidth,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: split ? 64 : 0,
            runSpacing: split ? 0 : logoSpacing ?? 0,
            children: [
              SizedBox(
                width: split ? 260 : formWidth,
                child: Center(
                  child: split || logoSpacing != null
                      ? SizedBox(
                          width: split ? 260 : 170,
                          height: split ? 260 : 170,
                          child: SvgPicture.asset(
                            'lib/assets/tvScoreLogin.svg',
                            colorMapper:
                                Theme.of(context).brightness == Brightness.light
                                ? const LightLogoColorMapper()
                                : null,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              SizedBox(width: formWidth, child: child),
            ],
          ),
        ),
      );
    },
  );
}
