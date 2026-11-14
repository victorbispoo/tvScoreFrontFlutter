import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/app_theme.dart';

class FloatingNavigationBar extends StatelessWidget {
  const FloatingNavigationBar({super.key, required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _icons = [HugeIcons.strokeRoundedHome01, HugeIcons.strokeRoundedFavourite, HugeIcons.strokeRoundedUser];
  static const _labels = ['Início', 'Favoritos', 'Perfil'];

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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 16, offset: const Offset(0, 5))],
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth / _labels.length;
            return Stack(children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: index * width + 5,
                top: 5,
                bottom: 5,
                width: width - 10,
                child: DecoratedBox(decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: .2), borderRadius: BorderRadius.circular(30))),
              ),
              Row(children: List.generate(_labels.length, (i) {
                final selected = i == index;
                return Expanded(child: _NavigationItem(icon: _icons[i], label: _labels[i], selected: selected, onTap: () => onSelected(i)));
              })),
            ]);
          }),
        ),
      ),
    ),
  );
}

class _NavigationItem extends StatefulWidget {
  const _NavigationItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final List<List<dynamic>> icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

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
    child: AnimatedScale(
      scale: _pressed ? .96 : 1,
      duration: const Duration(milliseconds: 120),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedScale(scale: widget.selected ? 1.08 : 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic, child: HugeIcon(icon: widget.icon, size: 23, color: widget.selected ? const Color(0xFF75ADFF) : const Color(0xFFA0ADC0))),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 250), style: TextStyle(fontSize: 11, fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400, color: widget.selected ? Colors.white : const Color(0xFFA0ADC0)), child: Text(widget.label)),
      ]),
    ),
  );
}
