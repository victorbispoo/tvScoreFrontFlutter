import 'package:flutter/material.dart';
import 'package:tv_score_front_flutter/pages/favorites_page.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'services/api_services.dart';
import 'widgets/floating_navigation_bar.dart';
import 'widgets/tv_score_snackbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loggedIn = await ApiService().restoreSession();
  runApp(TvScoreApp(loggedIn: loggedIn));
}

class TvScoreApp extends StatelessWidget {
  const TvScoreApp({super.key, this.loggedIn = false});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Score',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.home: (_) => const AppShell(),
      },
      home: loggedIn ? const AppShell() : const LoginPage(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final PageController _pages = PageController();
  int? _navigationTarget;

  static const _pageDuration = Duration(milliseconds: 300);

  Future<void> _selectPage(int index) async {
    if (!_pages.hasClients || index == _navigationTarget) return;
    if (index == _index && _navigationTarget == null) return;
    _navigationTarget = index;
    try {
      await _pages.animateToPage(
        index,
        duration: _pageDuration,
        curve: Curves.easeOutCubic,
      );
    } finally {
      if (_navigationTarget == index) _navigationTarget = null;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: TvScoreSnackbar.withFloatingNavigation(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: PageView(
                controller: _pages,
                onPageChanged: (index) => setState(() => _index = index),
                children: [
                  const HomePage(),
                  FavoritesPage(onExplore: () => _selectPage(0)),
                  ProfilePage(isActive: _index == 2),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: FloatingNavigationBar(
                  index: _index,
                  onSelected: _selectPage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
