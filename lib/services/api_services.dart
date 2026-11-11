import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_contents.dart';
import '../models/content_metadata.dart';
import '../models/review.dart';

part 'auth_service.dart';
part 'content_service.dart';
part 'favorites_service.dart';
part 'reviews_service.dart';
part 'preferences_service.dart';

class ApiService {
  static const maxSearchPage = 500;
  // Use --dart-define=USE_MOCK_MOVIES=false para voltar ao backend.
  static const useMockContents = bool.fromEnvironment(
    'USE_MOCK_MOVIES',
    defaultValue: false,
  );
  final Dio dio = Dio(
    BaseOptions(baseUrl: 'https://tvscore-backend.onrender.com/api'),
  );

  Options get _authorizationOptions =>
      Options(headers: {'Authorization': 'Bearer ${ApiService.token}'});

  static String? token;
  static int _sessionVersion = 0;

  static void _checkSession(int version) {
    if (version != _sessionVersion) {
      throw StateError('A sessão mudou. Entre novamente na sua conta.');
    }
  }

  static String userName = '';
  static String userEmail = '';
  static List<Map<String, String>> savedContents = [];
  static List<Review> reviews = [];

  Future<void> open(String email, String defaultName) async {
    final preferences = SharedPreferencesAsync();
    final value = await preferences.getString('tv_score_library_$email');
    final data = value == null
        ? <String, dynamic>{}
        : jsonDecode(value) as Map<String, dynamic>;

    if (data.containsKey('saved') || data.containsKey('reviews')) {
      data.remove('saved');
      data.remove('reviews');
      await preferences.setString('tv_score_library_$email', jsonEncode(data));
    }

    userEmail = email;
    userName = data['name'] ?? defaultName;
    savedContents = [];
    reviews = [];
  }

  Future<void> updateName(String name) async {
    final nomeTrim = name.trim();

    if (nomeTrim.isEmpty) {
      throw ArgumentError('Informe seu nome');
    }

    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      'tv_score_library_$userEmail',
      jsonEncode({'name': nomeTrim}),
    );

    userName = nomeTrim;
  }
}
