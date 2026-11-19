import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_routes.dart';
import 'core/app_shell.dart';
import 'core/app_theme.dart';
import 'core/recovery_browser_url.dart'
    if (dart.library.js_interop) 'core/recovery_browser_url_web.dart';
import 'core/system_ui_style.dart';
import 'core/theme_controller.dart';
import 'services/api_services.dart';

export 'core/app_shell.dart' show AppShell;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = Uri.base;
  final recoveryRoute = kIsWeb ? AppRoutes.recoveryRouteFromUrl(url) : null;
  if (recoveryRoute != null) {
    replaceRecoveryBrowserUrl(AppRoutes.recoveryUrlWithoutToken(url));
  }
  await ThemeController.instance.restore();
  if (recoveryRoute == null) await ApiService().restoreSession();
  runApp(TvScoreApp(recoveryRoute: recoveryRoute));
}

class TvScoreApp extends StatelessWidget {
  const TvScoreApp({super.key, this.recoveryRoute});

  final RouteSettings? recoveryRoute;

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
        initialRoute: recoveryRoute?.name,
        onGenerateInitialRoutes: recoveryRoute == null
            ? null
            : (_) => [AppRoutes.generate(recoveryRoute!)!],
        home: recoveryRoute == null ? const AppShell() : null,
      ),
    );
  }
}
