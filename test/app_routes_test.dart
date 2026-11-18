import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';
import 'package:tv_score_front_flutter/core/recovery_browser_url.dart'
    if (dart.library.js_interop) 'package:tv_score_front_flutter/core/recovery_browser_url_web.dart';

void main() {
  test(
    'reset links isolate tokens from route names and clean path and hash URLs',
    () {
      final token = 'a' * 43;
      for (final path in ['/redefinir-senha', '/#/redefinir-senha']) {
        final url = Uri.parse('https://example.test$path?token=$token');
        final entry = AppRoutes.recoveryRouteFromUrl(url)!;
        expect(entry.name, AppRoutes.resetPassword);
        expect(entry.arguments, token);
        expect(AppRoutes.generate(entry)!.settings.arguments, isNull);
        expect(AppRoutes.recoveryUrlWithoutToken(url).toString(), path);
      }
      final repeated = Uri.parse(
        'https://example.test/redefinir-senha?token=a&token=b',
      );
      expect(AppRoutes.recoveryRouteFromUrl(repeated)?.arguments, isNull);
      final malformed = Uri.parse(
        'https://example.test/redefinir-senha?token=%FF',
      );
      expect(AppRoutes.recoveryRouteFromUrl(malformed)?.arguments, isNull);
    },
  );

  if (kIsWeb) {
    test(
      'browser removes token from the address without leaving the current page',
      () {
        final original = Uri.base;
        try {
          final reset = Uri(
            path: original.path,
            fragment: '/redefinir-senha?token=example',
          );
          replaceRecoveryBrowserUrl(reset);
          expect(
            AppRoutes.recoveryRouteFromUrl(Uri.base)?.arguments,
            'example',
          );
          replaceRecoveryBrowserUrl(
            AppRoutes.recoveryUrlWithoutToken(Uri.base),
          );
          expect(Uri.base.fragment, '/redefinir-senha');
          expect(Uri.base.query, isEmpty);
        } finally {
          replaceRecoveryBrowserUrl(original);
        }
      },
    );
  }
  test(
    'central routes preserve settings and reject invalid details arguments',
    () {
      for (final name in [
        AppRoutes.login,
        AppRoutes.home,
        AppRoutes.register,
        AppRoutes.search,
        AppRoutes.myReviews,
      ]) {
        final settings = RouteSettings(name: name);
        expect(AppRoutes.generate(settings)!.settings, same(settings));
      }
      expect(AppRoutes.generate(const RouteSettings(name: '/unknown')), isNull);
      expect(
        () => AppRoutes.generate(const RouteSettings(name: AppRoutes.details)),
        throwsArgumentError,
      );
      final settings = RouteSettings(
        name: AppRoutes.details,
        arguments: (
          content: <String, String>{'id': '1'},
          heroTag: 'poster',
          onFavoriteChanged: null,
        ),
      );
      expect(AppRoutes.generate(settings)!.settings, same(settings));
    },
  );
}
