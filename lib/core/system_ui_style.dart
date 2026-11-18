import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

SystemUiOverlayStyle appSystemUiStyle(
  ThemeData theme, {
  Brightness? statusIcons,
}) {
  final icons = theme.brightness == Brightness.light
      ? Brightness.dark
      : Brightness.light;
  final status = statusIcons ?? icons;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: status,
    statusBarBrightness: status == Brightness.dark
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarColor: theme.scaffoldBackgroundColor,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: true,
  );
}
