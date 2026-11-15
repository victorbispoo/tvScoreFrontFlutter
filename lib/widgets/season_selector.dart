import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';

class SeasonSelector extends StatefulWidget {
  const SeasonSelector({
    super.key,
    required this.seasons,
    required this.value,
    required this.onChanged,
  });

  final List<int> seasons;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<SeasonSelector> createState() => _SeasonSelectorState();
}

class _SeasonSelectorState extends State<SeasonSelector> {
  final _anchor = GlobalKey();
  bool _open = false;

  Future<void> _showMenu() async {
    if (_open) return;
    final scrollPosition = Scrollable.maybeOf(context)?.position;
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    setState(() => _open = true);
    try {
      final selected = await showGeneralDialog<int>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 220),
        transitionBuilder: (context, animation, _, child) {
          final curved = animation.drive(
            CurveTween(curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, -.015),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        pageBuilder: (context, _, _) => _SeasonMenu(
          seasons: widget.seasons,
          selected: widget.value,
          anchor: _anchor,
          overlay: overlay,
          scrollPosition: scrollPosition,
        ),
      );
      if (mounted && selected != null) widget.onChanged(selected);
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    expanded: _open,
    child: ClipRRect(
      key: _anchor,
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(72, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: const Color(0xE6172B46),
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0x3375ADFF)),
            shape: const StadiumBorder(),
          ),
          onPressed: _showMenu,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.value == 0 ? 'Especiais' : 'T${widget.value}'),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _open ? .5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: const Icon(HugeIconsStroke.arrowDown01, size: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SeasonMenu extends StatefulWidget {
  const _SeasonMenu({
    required this.seasons,
    required this.selected,
    required this.anchor,
    required this.overlay,
    this.scrollPosition,
  });
  final List<int> seasons;
  final int selected;
  final GlobalKey anchor;
  final RenderBox overlay;
  final ScrollPosition? scrollPosition;

  @override
  State<_SeasonMenu> createState() => _SeasonMenuState();
}

class _SeasonMenuState extends State<_SeasonMenu> {
  late int _selected = widget.selected;
  bool _closing = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollPosition?.addListener(_followAnchor);
  }

  void _followAnchor() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.scrollPosition?.removeListener(_followAnchor);
    super.dispose();
  }

  Future<void> _select(int value) async {
    if (_closing) return;
    setState(() {
      _selected = value;
      _closing = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted && ModalRoute.of(context)!.isCurrent) {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) {
      final box =
          widget.anchor.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return const SizedBox.shrink();
      final media = MediaQuery.of(context);
      return CustomSingleChildLayout(
        delegate: _SeasonMenuLayout(
          box.localToGlobal(Offset.zero, ancestor: widget.overlay) & box.size,
          media.padding,
          media.viewInsets.bottom,
        ),
        child: ClipRRect(
          key: const ValueKey('season-menu'),
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE6172B46),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x3375ADFF)),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final season in widget.seasons)
                      Semantics(
                        selected: season == _selected,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: season == _selected
                                ? const Color(0xFF294D83)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              foregroundColor: season == _selected
                                  ? Colors.white
                                  : const Color(0xFFA0ADC0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () => _select(season),
                            child: Text(
                              season == 0 ? 'Especiais' : 'Temporada $season',
                            ),
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
    },
  );
}

class _SeasonMenuLayout extends SingleChildLayoutDelegate {
  _SeasonMenuLayout(this.anchor, this.padding, this.keyboardHeight);
  final Rect anchor;
  final EdgeInsets padding;
  final double keyboardHeight;

  double _bottom(Size size) =>
      size.height - math.max(padding.bottom, keyboardHeight) - 12;
  double get _top => padding.top + 12;
  bool _below(Size size) =>
      _bottom(size) - anchor.bottom - 8 >= math.min(320, anchor.top - _top - 8);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final size = constraints.biggest;
    final space = _below(size)
        ? _bottom(size) - anchor.bottom - 8
        : anchor.top - _top - 8;
    final width = math.min(
      240.0,
      math.max(0.0, size.width - padding.horizontal - 24),
    );
    return BoxConstraints.tightFor(width: width).copyWith(
      minHeight: 0,
      maxHeight: math.max(
        0.0,
        math.min(math.min(320.0, space), _bottom(size) - _top),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (anchor.right - childSize.width).clamp(
      padding.left + 12,
      math.max(
        padding.left + 12,
        size.width - padding.right - 12 - childSize.width,
      ),
    ),
    (_below(size) ? anchor.bottom + 8 : anchor.top - 8 - childSize.height)
        .clamp(_top, math.max(_top, _bottom(size) - childSize.height)),
  );

  @override
  bool shouldRelayout(_SeasonMenuLayout oldDelegate) => true;
}
