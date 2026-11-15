import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static void selection() => HapticFeedback.selectionClick();
  static void confirmation() => HapticFeedback.lightImpact();
  static void error() => HapticFeedback.lightImpact();
}
