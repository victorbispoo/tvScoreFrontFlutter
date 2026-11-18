import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class TvScoreSnackbar {
  const TvScoreSnackbar._();

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    HugeIconsStroke.checkmarkCircle01,
    const Color(0xFF70D6B3),
    const Duration(seconds: 3),
  );

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    context,
    message,
    HugeIconsStroke.alertCircle,
    const Color(0xFFE59AA5),
    const Duration(seconds: 5),
    actionLabel: actionLabel,
    onAction: onAction,
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message,
    HugeIconsStroke.alert02,
    const Color(0xFFE8BE70),
    const Duration(seconds: 4),
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message,
    HugeIconsStroke.informationCircle,
    const Color(0xFF75ADFF),
    const Duration(seconds: 3),
  );

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color color,
    Duration duration, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final navigationVisible = context
        .getInheritedWidgetOfExactType<_FloatingNavigationScope>()
        ?.visible;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    if (Theme.of(context).brightness == Brightness.light) {
      color = HSLColor.fromColor(color).withLightness(.32).toColor();
    }
    messenger.showSnackBar(
      SnackBar(
        content: _SnackbarContent(message: message, icon: icon, color: color),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                onPressed: onAction,
              )
            : null,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          navigationVisible == true
              ? 80 + MediaQuery.paddingOf(context).bottom
              : 16,
        ),
      ),
    );
  }

  static Widget withFloatingNavigation({required Widget child}) =>
      _FloatingNavigationScope(visible: true, child: child);
}

class _FloatingNavigationScope extends InheritedWidget {
  const _FloatingNavigationScope({required this.visible, required super.child});

  final bool visible;

  @override
  bool updateShouldNotify(_FloatingNavigationScope oldWidget) =>
      visible != oldWidget.visible;
}

class _SnackbarContent extends StatelessWidget {
  const _SnackbarContent({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.35,
                    ),
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
