import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/app_theme.dart';

class FloatingNavigationBar extends StatefulWidget {
  const FloatingNavigationBar({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

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
  late final ValueNotifier<double> _position = ValueNotifier(
    widget.index.toDouble(),
  );
  bool _dragging = false;
  int? _settlingTarget;
  Timer? _settleTimeout;
  static const _snapDuration = Duration(milliseconds: 220);

  @override
  void didUpdateWidget(covariant FloatingNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.index != oldWidget.index) {
      if (_settlingTarget == null || widget.index == _settlingTarget) {
        _settlingTarget = null;
        _settleTimeout?.cancel();
        _position.value = widget.index.toDouble();
      }
    }
  }

  @override
  void dispose() {
    _settleTimeout?.cancel();
    _position.dispose();
    super.dispose();
  }

  void _startDrag(DragStartDetails _) {
    _settleTimeout?.cancel();
    _settlingTarget = null;
    setState(() => _dragging = true);
  }

  void _updateDrag(DragUpdateDetails details, double slotWidth) {
    _position.value = (_position.value + details.delta.dx / slotWidth).clamp(
      0.0,
      (FloatingNavigationBar._labels.length - 1).toDouble(),
    );
  }

  void _finishDrag({bool canceled = false}) {
    if (!_dragging) return;
    final target = canceled ? widget.index : _position.value.round();
    setState(() => _dragging = false);
    _position.value = target.toDouble();
    if (!canceled && target != widget.index) {
      _settlingTarget = target;
      _settleTimeout?.cancel();
      _settleTimeout = Timer(const Duration(milliseconds: 400), () {
        if (!mounted || _settlingTarget != target) return;
        _settlingTarget = null;
        _position.value = widget.index.toDouble();
      });
      widget.onSelected(target);
    }
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
              return ValueListenableBuilder<double>(
                valueListenable: _position,
                builder: (context, position, _) => Stack(
                  children: [
                    AnimatedPositioned(
                      duration: _dragging ? Duration.zero : _snapDuration,
                      curve: Curves.easeOutCubic,
                      left: position * width + 5,
                      top: 5,
                      bottom: 5,
                      width: width - 10,
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
                          final selected = i == widget.index;
                          return Expanded(
                            child: _NavigationItem(
                              icon: FloatingNavigationBar._icons[i],
                              label: FloatingNavigationBar._labels[i],
                              selected: (position - i).abs() < .5,
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
                ),
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
    required this.selected,
    required this.onTap,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
  });
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
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
            AnimatedScale(
              scale: widget.selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: HugeIcon(
                icon: widget.icon,
                size: 23,
                color: widget.selected
                    ? const Color(0xFF75ADFF)
                    : const Color(0xFFA0ADC0),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                color: widget.selected ? Colors.white : const Color(0xFFA0ADC0),
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    ),
  );
}
