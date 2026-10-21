import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../models/review.dart';

part 'auth_service.dart';
part 'movie_service.dart';
part 'favorites_service.dart';
part 'reviews_service.dart';

class ApiService {
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
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://10.106.75.24:8080/api'));

  static String? token;

  // Dados compartilhados entre as páginas do app.
  static String userName = '';
  static String userEmail = '';
  static List<Map<String, String>> savedMovies = [];
  static List<Review> reviews = [];

  // Carrega os dados locais da conta depois do login.
  Future<void> open(String email, String defaultName) async {
    final preferences = SharedPreferencesAsync();
    final value = await preferences.getString('tv_score_library_$email');
    final data = value == null
        ? <String, dynamic>{}
        : jsonDecode(value) as Map<String, dynamic>;

    userEmail = email;
    userName = data['name'] ?? defaultName;
    savedMovies = [];
    reviews = [];

    for (final movie in data['saved'] ?? []) {
      savedMovies.add(Map<String, String>.from(movie));
    }
    for (final review in data['reviews'] ?? []) {
      reviews.add(
        Review(
          movie: Map<String, String>.from(review['movie']),
          rating: review['rating'],
          comment: review['comment'],
          date: DateTime.parse(review['date']),
        ),
      );
    }
  }

  // Grava no dispositivo antes de atualizar os dados usados pelas telas.
  Future<void> _saveLibrary(
    List<Map<String, String>> movies,
    List<Review> movieReviews,
    String name,
  ) async {
    final reviewData = <Map<String, dynamic>>[];
    for (final review in movieReviews) {
      reviewData.add({
        'movie': review.movie,
        'rating': review.rating,
        'comment': review.comment,
        'date': review.date.toIso8601String(),
      });
    }

    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      'tv_score_library_$userEmail',
      jsonEncode({'name': name, 'saved': movies, 'reviews': reviewData}),
    );
    savedMovies = movies;
    reviews = movieReviews;
    userName = name;
  }

  Future<void> updateName(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Informe seu nome.');
    }
    await _saveLibrary(savedMovies, reviews, name.trim());
  }
}
