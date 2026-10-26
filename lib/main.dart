import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'core/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/search_page.dart';
import 'services/api_services.dart';

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

  @override
  Widget build(BuildContext context) {
    // Reconstrói as páginas ao mudar de aba para atualizar listas e contagens.
    final pages = [HomePage(), SearchPage(), ProfilePage()];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedHome01,
              strokeWidth: 3,
            ),
            label: 'Início',
          ),

          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              strokeWidth: 3,
            ),
            label: 'Pesquisar',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedUser),
            selectedIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              strokeWidth: 3,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
