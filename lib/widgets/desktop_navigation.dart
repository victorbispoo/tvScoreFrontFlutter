import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/light_logo_color_mapper.dart';

class DesktopNavigation extends StatelessWidget {
  const DesktopNavigation({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  static const _labels = ['Início', 'Favoritos', 'Perfil'];
  static const _icons = [
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedFavourite,
    HugeIcons.strokeRoundedUser,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox.expand(
      child: Material(
        color: colors.surface,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: SvgPicture.asset(
                    'lib/assets/logoTvScore.svg',
                    width: 132,
                    semanticsLabel: 'TVScore',
                    colorMapper: theme.brightness == Brightness.light
                        ? const LightLogoColorMapper()
                        : null,
                  ),
                ),
                for (var i = 0; i < _labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      selected: index == i,
                      child: Material(
                        animationDuration: const Duration(milliseconds: 180),
                        color: index == i
                            ? colors.primary.withValues(alpha: .14)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          hoverColor: colors.primary.withValues(alpha: .07),
                          onTap: () => onSelected(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                HugeIcon(
                                  icon: _icons[i],
                                  size: 23,
                                  color: index == i
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _labels[i],
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: index == i
                                          ? colors.primary
                                          : colors.onSurface,
                                      fontWeight: index == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
