import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_contents.dart';
import '../models/review.dart';

part 'auth_service.dart';
part 'content_service.dart';
part 'favorites_service.dart';
part 'reviews_service.dart';

class ApiService {
  // Use --dart-define=USE_MOCK_MOVIES=false para voltar ao backend.
  static const useMockContents = bool.fromEnvironment(
    'USE_MOCK_MOVIES',
    defaultValue: false,
  );
  static const generos = <int, String>{
    28: 'Ação',
    12: 'Aventura',
    16: 'Animação',
    35: 'Comédia',
    80: 'Crime',
    99: 'Documentário',
    18: 'Drama',
    10751: 'Família',
    14: 'Fantasia',
    36: 'História',
    27: 'Terror',
    10402: 'Música',
    9648: 'Mistério',
    10749: 'Romance',
    878: 'Ficção Científica',
    10770: 'Filme para TV',
    53: 'Suspense',
    10752: 'Guerra',
    37: 'Faroeste',
  };
  final Dio dio = Dio(
    BaseOptions(baseUrl: 'https://tvscore-backend.onrender.com/api'),
  );

  static String? token;

  // Dados compartilhados entre as páginas do app.
  static String userName = '';
  static String userEmail = '';
  static List<Map<String, String>> savedContents = [];
  static List<Review> reviews = [];

  // Carrega os dados locais da conta depois do login.
  Future<void> open(String email, String defaultName) async {
    final preferences = SharedPreferencesAsync();
    final value = await preferences.getString('tv_score_library_$email');
    final data = value == null
        ? <String, dynamic>{}
        : jsonDecode(value) as Map<String, dynamic>;

    // Remove favoritos antigos do dispositivo
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
    await preferences.setString('tv_score_library_$userEmail', jsonEncode({'name': nomeTrim}),
    );

    userName = nomeTrim;
  }
}
