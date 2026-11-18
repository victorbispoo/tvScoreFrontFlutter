import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_haptics.dart';

class TvScoreSegmentedControl<T> extends StatefulWidget {
  const TvScoreSegmentedControl({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.textScale = 1,
  });

  final Map<T, String> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final double textScale;

  @override
  State<TvScoreSegmentedControl<T>> createState() =>
      _TvScoreSegmentedControlState<T>();
}

class _TvScoreSegmentedControlState<T>
    extends State<TvScoreSegmentedControl<T>> {
  final _dragPosition = ValueNotifier<double?>(null);
  static const _snapDuration = Duration(milliseconds: 180);
  static const _segmentWidth = 112.0;
  static const _inset = 3.0;

  @override
  void didUpdateWidget(covariant TvScoreSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue ||
        !listEquals(
          oldWidget.options.keys.toList(),
          widget.options.keys.toList(),
        )) {
      _dragPosition.value = null;
    }
  }

  @override
  void dispose() {
    _dragPosition.dispose();
    super.dispose();
  }

  void _updateDrag(DragUpdateDetails details, double width, bool rtl) {
    final position = _dragPosition.value;
    if (position == null) return;
    final next = (position + details.delta.dx / width * (rtl ? -1 : 1)).clamp(
      0.0,
      (widget.options.length - 1).toDouble(),
    );
    _dragPosition.value = next;
    if (next.round() != position.round()) AppHaptics.selection();
  }

  void _finishDrag({bool canceled = false}) {
    final position = _dragPosition.value;
    if (position == null) return;
    _dragPosition.value = null;
    if (canceled) return;
    final value = widget.options.keys.elementAt(position.round());
    if (value != widget.selectedValue) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.options.isNotEmpty);
    assert(widget.options.containsKey(widget.selectedValue));
    final values = widget.options.keys.toList();
    final selectedIndex = values.indexOf(widget.selectedValue);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: values.length * _segmentWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: Theme.of(context).brightness == Brightness.light ? 1 : .5,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final slotWidth = constraints.maxWidth / values.length;
            return ValueListenableBuilder<double?>(
              valueListenable: _dragPosition,
              builder: (context, dragPosition, _) =>
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: dragPosition ?? selectedIndex.toDouble()),
                    duration:
                        dragPosition == null &&
                            !MediaQuery.disableAnimationsOf(context)
                        ? _snapDuration
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    builder: (context, position, _) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) =>
                          _dragPosition.value = position,
                      onHorizontalDragUpdate: (details) =>
                          _updateDrag(details, slotWidth, rtl),
                      onHorizontalDragEnd: (_) => _finishDrag(),
                      onHorizontalDragCancel: () => _finishDrag(canceled: true),
                      child: Listener(
                        onPointerCancel: (_) => _finishDrag(canceled: true),
                        child: Stack(
                          children: [
                            PositionedDirectional(
                              key: const ValueKey('segmented-indicator'),
                              start: position * slotWidth + _inset,
                              top: _inset,
                              bottom: _inset,
                              width: slotWidth - _inset * 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: .28),
                                  borderRadius: BorderRadius.circular(21),
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(values.length, (index) {
                                final emphasis = (1 - (position - index).abs())
                                    .clamp(0.0, 1.0);
                                return Expanded(
                                  child: Semantics(
                                    selected:
                                        values[index] == widget.selectedValue,
                                    inMutuallyExclusiveGroup: true,
                                    child: TextButton(
                                      onPressed: () {
                                        if (values[index] ==
                                            widget.selectedValue) {
                                          return;
                                        }
                                        AppHaptics.selection();
                                        widget.onChanged(values[index]);
                                      },
                                      style: TextButton.styleFrom(
                                        animationDuration: Duration.zero,
                                        minimumSize: const Size(0, 48),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        foregroundColor: Color.lerp(
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          emphasis,
                                        ),
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              fontSize: 13 * widget.textScale,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      child: Text(
                                        widget.options[values[index]]!,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}
