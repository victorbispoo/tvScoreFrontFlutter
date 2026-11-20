import 'package:flutter/material.dart';

import '../models/content_metadata.dart';
import '../pages/details_page.dart';
import '../pages/details_route_page.dart';
import '../pages/login_page.dart';
import '../pages/my_reviews_page.dart';
import '../pages/password_recovery_page.dart';
import '../pages/register_page.dart';
import '../pages/search_page.dart';
import '../services/api_services.dart';
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
  static const returnToOriginArguments = (returnToOrigin: true);

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

  static bool isDetailsRoute(String name) {
    final path = Uri.tryParse(name)?.path;
    return path == details || (path?.startsWith('$details/') ?? false);
  }

  static List<Route<dynamic>> initialDetailsRoutes(String name) => [
    generate(const RouteSettings(name: Navigator.defaultRouteName))!,
    generate(RouteSettings(name: name))!,
  ];

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
          returnToOrigin: settings.arguments == returnToOriginArguments,
        );
      case Navigator.defaultRouteName:
      case home:
        page = const AppShell();
      case register:
        page = RegisterPage(
          returnToOrigin: settings.arguments == returnToOriginArguments,
        );
      case search:
        page = const SearchPage();
      case myReviews:
        page = ValueListenableBuilder<int>(
          valueListenable: ApiService.sessionRevision,
          builder: (context, revision, _) => ApiService.hasSession
              ? MyReviewsPage(key: ValueKey(revision))
              : const AppShell(),
        );
      default:
        if (!isDetailsRoute(settings.name ?? '')) return null;
        page = _detailsPage(uri!.path, settings.arguments);
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }

  static Widget _detailsPage(String path, Object? arguments) {
    final segments = path.split('/');
    final type = switch (segments.length == 4 ? segments[2] : null) {
      'movie' => 'MOVIE',
      'tv' => 'TV',
      _ => null,
    };
    final id = segments.length == 4 && RegExp(r'^[0-9]+$').hasMatch(segments[3])
        ? int.tryParse(segments[3])
        : null;
    if (type == null || id == null || id <= 0 || id > 9007199254740991) {
      return const DetailsRouteError(message: 'Link de detalhes inválido.');
    }
    if (arguments is DetailsArguments &&
        arguments.content.contentKey == (id.toString(), type)) {
      return DetailsPage(
        content: arguments.content,
        heroTag: arguments.heroTag,
        onFavoriteChanged: arguments.onFavoriteChanged,
      );
    }
    return DetailsRoutePage(id: id, type: type);
  }

  static Future<void> openDetails(
    BuildContext context, {
    required Map<String, String> content,
    Object? heroTag,
    VoidCallback? onFavoriteChanged,
  }) async {
    final reference = content.apiReference;
    final type = reference.type == 'MOVIE' ? 'movie' : 'tv';
    await Navigator.of(context).pushNamed<void>(
      '$details/$type/${reference.id}',
      arguments: (
        content: content,
        heroTag: heroTag,
        onFavoriteChanged: onFavoriteChanged,
      ),
    );
  }
}
