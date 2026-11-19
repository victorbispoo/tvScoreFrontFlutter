import 'package:flutter/material.dart';

import '../pages/favorites_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../services/api_services.dart';
import '../widgets/desktop_navigation.dart';
import '../widgets/floating_navigation_bar.dart';
import '../widgets/tv_score_snackbar.dart';

import 'app_breakpoints.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final PageController _pages = PageController();
  ({int index, Future<void> animation})? _navigationTarget;

  static const _pageDuration = Duration(milliseconds: 300);
  static const _fadeHalf = Duration(milliseconds: 100);
  late final _fade = AnimationController(vsync: this, duration: _fadeHalf);
  bool _useDesktopTransition = false;

  Future<void> _selectDesktopPage(int index) async {
    if (!_pages.hasClients || index == _index || _fade.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(index);
      return;
    }
    try {
      await _fade
          .animateTo(.5, duration: _fadeHalf, curve: Curves.easeOutCubic)
          .orCancel;
      if (!_useDesktopTransition) return;
      _pages.jumpToPage(index);
      await _fade
          .animateTo(1, duration: _fadeHalf, curve: Curves.easeOutCubic)
          .orCancel;
    } on TickerCanceled {
      return;
    } finally {
      if (mounted) _fade.reset();
    }
  }

  Future<void> _selectPage(int index) async {
    if (_useDesktopTransition) return _selectDesktopPage(index);
    if (!_pages.hasClients || index == _navigationTarget?.index) return;
    if (_pages.page == index && _navigationTarget == null) return;
    final animation = _pages.animateToPage(
      index,
      duration: _pageDuration,
      curve: Curves.easeOutCubic,
    );
    _navigationTarget = (index: index, animation: animation);
    try {
      await animation;
    } finally {
      if (_navigationTarget?.animation == animation) _navigationTarget = null;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = AppBreakpoints.isDesktop(constraints.maxWidth);
        final adaptTransition = desktop && AppBreakpoints.supportsWidePages;
        if (adaptTransition != _useDesktopTransition) {
          _useDesktopTransition = adaptTransition;
          final index = _index;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                _useDesktopTransition != adaptTransition ||
                !_pages.hasClients) {
              return;
            }
            _fade.reset();
            if (_pages.page != index) _pages.jumpToPage(index);
          });
        }
        final bottomPadding = desktop
            ? 0.0
            : FloatingNavigationBar.scrollClearance(context);
        return Scaffold(
          extendBody: true,
          body: TvScoreSnackbar.withFloatingNavigation(
            visible: !desktop,
            child: Row(
              children: [
                SizedBox(
                  width: desktop ? 208 : 0,
                  child: desktop
                      ? DesktopNavigation(
                          index: _index,
                          onSelected: _selectPage,
                        )
                      : null,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SafeArea(
                        bottom: desktop,
                        child: AnimatedBuilder(
                          animation: _fade,
                          builder: (context, child) {
                            final progress = adaptTransition
                                ? _fade.value
                                : 0.0;
                            final opacity = (1 - progress * 2).abs();
                            final dy = progress <= .5
                                ? -10 * (1 - opacity)
                                : 10 * (1 - opacity);
                            return IgnorePointer(
                              ignoring:
                                  adaptTransition &&
                                  progress > 0 &&
                                  progress < 1,
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(0, dy),
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: PageView(
                            controller: _pages,
                            physics: adaptTransition
                                ? const NeverScrollableScrollPhysics()
                                : null,
                            onPageChanged: (index) =>
                                setState(() => _index = index),
                            children: [
                              for (final (index, page) in [
                                HomePage(bottomPadding: bottomPadding),
                                ValueListenableBuilder<int>(
                                  valueListenable: ApiService.sessionRevision,
                                  builder: (context, revision, _) =>
                                      FavoritesPage(
                                        key: ValueKey(revision),
                                        bottomPadding: bottomPadding,
                                        onExplore: () => _selectPage(0),
                                      ),
                                ),
                                ValueListenableBuilder<int>(
                                  valueListenable: ApiService.sessionRevision,
                                  builder: (context, revision, _) =>
                                      ProfilePage(
                                        key: ValueKey(revision),
                                        isActive: _index == 2,
                                        bottomPadding: bottomPadding,
                                      ),
                                ),
                              ].indexed)
                                TickerMode(
                                  enabled: !adaptTransition || _index == index,
                                  child: page,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!desktop)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SafeArea(
                            top: false,
                            child: FloatingNavigationBar(
                              index: _index,
                              onSelected: _selectPage,
                              pageController: _pages,
                              onIndicatorDragStarted: () {
                                _navigationTarget = null;
                                _pages.position.hold(() {});
                              },
                              onIndicatorDragged: (position) {
                                _pages.jumpTo(
                                  position * _pages.position.viewportDimension,
                                );
                                _pages.position.hold(() {});
                              },
                              onIndicatorReleased: (position, target) {
                                _navigationTarget = null;
                                _pages.jumpTo(
                                  position * _pages.position.viewportDimension,
                                );
                                _selectPage(target);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
