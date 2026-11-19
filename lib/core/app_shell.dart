import 'package:flutter/material.dart';

import '../pages/favorites_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../widgets/desktop_navigation.dart';
import '../widgets/floating_navigation_bar.dart';
import '../widgets/tv_score_snackbar.dart';

import 'app_breakpoints.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final PageController _pages = PageController();
  ({int index, Future<void> animation})? _navigationTarget;

  static const _pageDuration = Duration(milliseconds: 300);

  Future<void> _selectPage(int index) async {
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
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = AppBreakpoints.isDesktop(constraints.maxWidth);
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
                        child: PageView(
                          controller: _pages,
                          onPageChanged: (index) =>
                              setState(() => _index = index),
                          children: [
                            HomePage(bottomPadding: bottomPadding),
                            FavoritesPage(
                              bottomPadding: bottomPadding,
                              onExplore: () => _selectPage(0),
                            ),
                            ProfilePage(
                              isActive: _index == 2,
                              bottomPadding: bottomPadding,
                            ),
                          ],
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
