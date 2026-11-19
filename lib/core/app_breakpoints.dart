import 'package:flutter/foundation.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static bool get supportsWidePages =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.android;

  static bool isDesktop(double width) => width >= desktop;
}
