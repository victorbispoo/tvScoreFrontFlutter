import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/app_haptics.dart';
import '../core/app_theme.dart';

class FloatingNavigationBar extends StatefulWidget {
  const FloatingNavigationBar({
    super.key,
    required this.index,
    required this.onSelected,
    this.pageController,
    this.onIndicatorReleased,
    this.onIndicatorDragStarted,
    this.onIndicatorDragged,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final PageController? pageController;
  final VoidCallback? onIndicatorDragStarted;
  final ValueChanged<double>? onIndicatorDragged;
  final void Function(double position, int target)? onIndicatorReleased;

  static const _icons = [
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedFavourite,
    HugeIcons.strokeRoundedUser,
  ];
  static const _labels = ['Início', 'Favoritos', 'Perfil'];

  @override
  State<FloatingNavigationBar> createState() => _FloatingNavigationBarState();
}

class _FloatingNavigationBarState extends State<FloatingNavigationBar> {
  double? _dragPosition;
  int? _dragStartIndex;
  bool get _dragging => _dragPosition != null;
  static const _indicatorInset = 5.0;

  double get _pagePosition {
    final controller = widget.pageController;
    return controller != null &&
            controller.hasClients &&
            controller.position.hasContentDimensions
        ? controller.page ?? widget.index.toDouble()
        : widget.index.toDouble();
  }

  void _startDrag(DragStartDetails _) {
    setState(() {
      _dragPosition = _pagePosition;
      _dragStartIndex = widget.index;
    });
    widget.onIndicatorDragStarted?.call();
  }

  void _updateDrag(DragUpdateDetails details, double slotWidth) {
    final previousCandidate = _dragPosition!.round();
    setState(
      () => _dragPosition = (_dragPosition! + details.delta.dx / slotWidth)
          .clamp(0.0, (FloatingNavigationBar._labels.length - 1).toDouble()),
    );
    widget.onIndicatorDragged?.call(_dragPosition!);
    if (_dragPosition!.round() != previousCandidate) AppHaptics.selection();
  }

  void _finishDrag({bool canceled = false}) {
    if (!_dragging) return;
    final target = canceled ? _dragStartIndex! : _dragPosition!.round();
    final position = _dragPosition!;
    // Transfer at the same fraction before the page starts snapping.
    if (widget.onIndicatorReleased != null) {
      widget.onIndicatorReleased!(position, target);
    } else if (!canceled && target != widget.index) {
      widget.onSelected(target);
    }
    setState(() {
      _dragPosition = null;
      _dragStartIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xE614253D),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth / FloatingNavigationBar._labels.length;
              return AnimatedBuilder(
                animation:
                    widget.pageController ?? const AlwaysStoppedAnimation(0),
                builder: (context, _) {
                  final position = (_dragPosition ?? _pagePosition).clamp(
                    0.0,
                    (FloatingNavigationBar._labels.length - 1).toDouble(),
                  );
                  return Stack(
                    children: [
                      Positioned(
                        key: const ValueKey('navigation-indicator'),
                        left: position * width + _indicatorInset,
                        top: 5,
                        bottom: 5,
                        width: width - _indicatorInset * 2,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(
                          FloatingNavigationBar._labels.length,
                          (i) {
                            final selected =
                                i == (_dragStartIndex ?? widget.index);
                            return Expanded(
                              child: _NavigationItem(
                                icon: FloatingNavigationBar._icons[i],
                                label: FloatingNavigationBar._labels[i],
                                selection: (1 - (position - i).abs()).clamp(
                                  0.0,
                                  1.0,
                                ),
                                onTap: () => widget.onSelected(i),
                                onHorizontalDragStart: selected
                                    ? _startDrag
                                    : null,
                                onHorizontalDragUpdate: selected
                                    ? (details) => _updateDrag(details, width)
                                    : null,
                                onHorizontalDragEnd: selected
                                    ? (_) => _finishDrag()
                                    : null,
                                onHorizontalDragCancel: selected
                                    ? () => _finishDrag(canceled: true)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _NavigationItem extends StatefulWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selection,
    required this.onTap,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
  });
  final List<List<dynamic>> icon;
  final String label;
  final double selection;
  final VoidCallback onTap;
  final GestureDragStartCallback? onHorizontalDragStart;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;
  final VoidCallback? onHorizontalDragCancel;

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: widget.onTap,
    onTapDown: (_) => setState(() => _pressed = true),
    onTapCancel: () => setState(() => _pressed = false),
    onTapUp: (_) => setState(() => _pressed = false),
    onHorizontalDragStart: widget.onHorizontalDragStart,
    onHorizontalDragUpdate: widget.onHorizontalDragUpdate,
    onHorizontalDragEnd: widget.onHorizontalDragEnd,
    onHorizontalDragCancel: widget.onHorizontalDragCancel,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerCancel: (_) => widget.onHorizontalDragCancel?.call(),
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1 + .08 * widget.selection,
              child: HugeIcon(
                icon: widget.icon,
                size: 23,
                color: Color.lerp(
                  const Color(0xFFA0ADC0),
                  const Color(0xFF75ADFF),
                  widget.selection,
                ),
              ),
            ),
            const SizedBox(height: 2),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.lerp(
                  FontWeight.w400,
                  FontWeight.w600,
                  widget.selection,
                ),
                color: Color.lerp(
                  const Color(0xFFA0ADC0),
                  Colors.white,
                  widget.selection,
                ),
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    ),
  );
}
