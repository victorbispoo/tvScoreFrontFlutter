import 'dart:convert';

abstract final class PasswordRecoveryRules {
  static final _token = RegExp(r'^[A-Za-z0-9_-]{43}$');
  static final _whitespace = RegExp(r'^\p{White_Space}*$', unicode: true);
  // Dart and JavaScript support this Unicode property; the lint tables lag behind.
  // ignore: valid_regexps
  static final _emoji = RegExp(r'\p{Emoji}', unicode: true);

  static bool isValidToken(String? token) =>
      token != null && token.length == 43 && _token.hasMatch(token);

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.runes.length < 6 || _whitespace.hasMatch(password)) {
      return 'Use pelo menos 6 caracteres e evite usar apenas espaços.';
    }
    if (password.contains('\u20e3') ||
        password.contains('\ufe0f') ||
        _emoji
            .allMatches(password)
            .any((match) => password.codeUnitAt(match.start) > 127)) {
      return 'A senha não pode conter emojis.';
    }
    if (utf8.encode(password).length > 72) {
      return 'A senha está muito longa. Use uma senha mais curta.';
    }
    return null;
  }
}
