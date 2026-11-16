import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/app_routes.dart';
import 'core/app_shell.dart';
import 'core/app_theme.dart';
import 'pages/login_page.dart';
import 'services/api_services.dart';

export 'core/app_shell.dart' show AppShell;

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
      onGenerateRoute: AppRoutes.generate,
      initialRoute: kIsWeb ? AppRoutes.recoveryRouteFromUrl(Uri.base) : null,
      home: loggedIn ? const AppShell() : const LoginPage(),
    );
  }
}
