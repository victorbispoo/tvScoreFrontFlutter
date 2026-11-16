import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tv_score_front_flutter/core/app_routes.dart';

void main() {
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
