import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/search_page.dart';
import 'package:hugeicons/hugeicons.dart';

void main() => runApp(const TvScoreApp());

class TvScoreApp extends StatelessWidget {
  const TvScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Score',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginPage(),
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
  final _pages = const [
    HomePage(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, strokeWidth:3 ,),
            label: 'Início',
          ),

          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, strokeWidth:3 ,),
            label: 'Pesquisar',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedUser, strokeWidth:3 ,),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
