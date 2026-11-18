import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

Future<bool?> showTvScoreConfirmation(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  String? emphasis,
  bool destructive = false,
}) => showGeneralDialog<bool>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black.withValues(alpha: .62),
  transitionDuration: const Duration(milliseconds: 180),
  transitionBuilder: (context, animation, _, child) {
    final progress = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: progress,
      child: ScaleTransition(
        scale: Tween(begin: .96, end: 1.0).animate(progress),
        child: child,
      ),
    );
  },
  pageBuilder: (context, _, _) => _TvScoreConfirmationDialog(
    title: title,
    description: description,
    confirmLabel: confirmLabel,
    emphasis: emphasis,
    destructive: destructive,
  ),
);

class _TvScoreConfirmationDialog extends StatelessWidget {
  const _TvScoreConfirmationDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.emphasis,
    required this.destructive,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String? emphasis;
  final bool destructive;

  static const _coral = Color(0xFFAD4F5B);
  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? _coral : Theme.of(context).colorScheme.primary;
    final emphasisAt = emphasis?.isNotEmpty == true
        ? description.indexOf(emphasis!)
        : -1;
    final maxHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      0.0,
      double.infinity,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 380, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (destructive) ...[
                          const SizedBox(width: 12),
                          Icon(
                            HugeIconsStroke.delete02,
                            color: accent,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      emphasisAt < 0
                          ? TextSpan(text: description)
                          : TextSpan(
                              children: [
                                TextSpan(
                                  text: description.substring(0, emphasisAt),
                                ),
                                TextSpan(
                                  text: emphasis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: description.substring(
                                    emphasisAt + emphasis!.length,
                                  ),
                                ),
                              ],
                            ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: .08),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(confirmLabel),
                          ),
                        ],
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
