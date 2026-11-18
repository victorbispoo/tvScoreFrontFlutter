import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_routes.dart';
import 'core/app_shell.dart';
import 'core/app_theme.dart';
import 'core/system_ui_style.dart';
import 'core/theme_controller.dart';
import 'pages/login_page.dart';
import 'services/api_services.dart';

export 'core/app_shell.dart' show AppShell;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.restore();
  final loggedIn = await ApiService().restoreSession();
  runApp(TvScoreApp(loggedIn: loggedIn));
}

class TvScoreApp extends StatelessWidget {
  const TvScoreApp({super.key, this.loggedIn = false});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, child) => MaterialApp(
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: appSystemUiStyle(Theme.of(context)),
          child: child!,
        ),
        title: 'TV Score',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        onGenerateRoute: AppRoutes.generate,
        initialRoute: kIsWeb ? AppRoutes.recoveryRouteFromUrl(Uri.base) : null,
        home: loggedIn ? const AppShell() : const LoginPage(),
      ),
    );
  }
}
