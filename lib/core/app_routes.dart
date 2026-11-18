import 'package:flutter/material.dart';

import '../pages/details_page.dart';
import '../pages/login_page.dart';
import '../pages/my_reviews_page.dart';
import '../pages/password_recovery_page.dart';
import '../pages/register_page.dart';
import '../pages/search_page.dart';
import 'app_shell.dart';

typedef DetailsArguments = ({
  Map<String, String> content,
  Object? heroTag,
  VoidCallback? onFavoriteChanged,
});

abstract final class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const register = '/register';
  static const search = '/search';
  static const myReviews = '/my-reviews';
  static const details = '/details';
  static const recovery = '/recuperar-senha';
  static const resetPassword = '/redefinir-senha';

  static RouteSettings? recoveryRouteFromUrl(Uri url) {
    final route = url.fragment.startsWith('/')
        ? Uri.tryParse(url.fragment)
        : url;
    if (route?.path != resetPassword) return null;
    return RouteSettings(
      name: resetPassword,
      arguments: _recoveryToken(route!),
    );
  }

  static String? _recoveryToken(Uri uri) {
    try {
      return uri.queryParametersAll['token']?.singleOrNull;
    } on FormatException {
      return null;
    }
  }

  static Uri recoveryUrlWithoutToken(Uri url) => Uri(
    path: url.path,
    fragment: url.fragment.startsWith('/') ? resetPassword : null,
  );

  static Route<dynamic>? generate(RouteSettings settings) {
    final Widget page;
    final uri = Uri.tryParse(settings.name ?? '');
    switch (uri?.path) {
      case recovery:
        page = PasswordRecoveryPage.request(
          email: settings.arguments is String
              ? settings.arguments as String
              : '',
        );
      case resetPassword:
        page = PasswordRecoveryPage.reset(
          token: settings.arguments is String
              ? settings.arguments as String
              : _recoveryToken(uri!),
        );
        // Keep the opaque token out of navigator observers and diagnostic route names.
        settings = const RouteSettings(name: resetPassword);
      case login:
        page = LoginPage(
          passwordReset: settings.arguments == const (passwordReset: true),
        );
      case home:
        page = const AppShell();
      case register:
        page = const RegisterPage();
      case search:
        page = const SearchPage();
      case myReviews:
        page = const MyReviewsPage();
      case details:
        final args = settings.arguments;
        if (args is! DetailsArguments) {
          throw ArgumentError.value(
            args,
            'arguments',
            'Expected DetailsArguments',
          );
        }
        page = DetailsPage(
          content: args.content,
          heroTag: args.heroTag,
          onFavoriteChanged: args.onFavoriteChanged,
        );
      default:
        return null;
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }

  static Future<void> openDetails(
    BuildContext context, {
    required Map<String, String> content,
    Object? heroTag,
    VoidCallback? onFavoriteChanged,
  }) async {
    await Navigator.of(context).pushNamed<void>(
      details,
      arguments: (
        content: content,
        heroTag: heroTag,
        onFavoriteChanged: onFavoriteChanged,
      ),
    );
  }
}
