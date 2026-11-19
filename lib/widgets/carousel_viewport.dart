import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '../core/app_breakpoints.dart';

// Own the controller independently of card sizes so resizing keeps scroll state.
class CarouselViewport extends StatefulWidget {
  const CarouselViewport({
    super.key,
    required this.itemCount,
    required this.itemWidth,
    required this.height,
    required this.itemBuilder,
  });

  final int itemCount;
  final double itemWidth;
  final double height;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<CarouselViewport> createState() => _CarouselViewportState();
}

class _CarouselViewportState extends State<CarouselViewport> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        (position.pixels + direction * position.viewportDimension * .85).clamp(
          0.0,
          position.maxScrollExtent,
        );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
      return;
    }
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);
    final behavior = ScrollConfiguration.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final overflows =
            widget.itemCount * (widget.itemWidth + 12) + 28 >
            constraints.maxWidth;
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            setState(() {});
            return false;
          },
          child: Column(
            children: [
              if (desktop && overflows)
                Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 8),
                  child: AnimatedBuilder(
                    animation: _scroll,
                    builder: (context, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final direction in [-1, 1])
                          IconButton(
                            tooltip: direction < 0 ? 'Anteriores' : 'Próximos',
                            onPressed:
                                !_scroll.hasClients ||
                                    (direction < 0
                                        ? _scroll.position.pixels <= 0
                                        : _scroll.position.pixels >=
                                              _scroll.position.maxScrollExtent)
                                ? null
                                : () => _move(direction),
                            icon: Icon(
                              direction < 0
                                  ? HugeIconsStroke.arrowLeft01
                                  : HugeIconsStroke.arrowRight01,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: .5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: widget.height,
                child: ScrollConfiguration(
                  behavior: desktop
                      ? behavior.copyWith(
                          dragDevices: {
                            ...behavior.dragDevices,
                            PointerDeviceKind.mouse,
                          },
                        )
                      : behavior,
                  child: ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.itemCount,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: widget.itemWidth,
                      child: widget.itemBuilder(context, index),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
