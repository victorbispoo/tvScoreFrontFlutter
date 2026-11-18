import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);
  static final instance = ThemeController._();
  static const preferenceKey = 'appearance_theme';
  Future<void> restore() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      preferenceKey,
    );
    value = ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> select(ThemeMode mode) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      preferenceKey,
      mode.name,
    )) {
      throw StateError('Não foi possível salvar a aparência.');
    }
    value = mode;
  }
}
