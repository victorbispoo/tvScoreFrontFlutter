import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../models/review.dart';


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
final Dio dio = Dio(
  BaseOptions(
    baseUrl: 'http://10.106.75.24:8080/api',
  ),
);

static String? token;

  Future<List<Map<String, String>>> getHighlights() async {
    final response = await dio.get('/filmes/em-alta');

    final results = response.data['results'] as List;

    return results.map<Map<String,String>>((filme){
      final data = filme['release_date'] as String? ?? '';
      final poster = filme['poster_path'] as String?;
      final ids = filme['genre_ids'] as List? ?? [];
      final generoPrincipal = ids.isEmpty ? 'não informado' : generos[ids.first] ?? 'não informado';
      return {
        'id' : filme['id'].toString(),
        'title' : filme['title'] as String? ?? 'Sem título',
        'overview' : filme['overview'] as String? ?? '',
        'year' : data.length >= 4 ? data.substring(0, 4) : '',
        'score' : (filme['vote_average'] as num?)?.toStringAsFixed(1) ?? '0.0',
        'poster_path' : poster == null || poster.isEmpty ? '' : 'https://image.tmdb.org/t/p/w500$poster',
        'genre_ids': filme['genre_ids']?.join(' | ') ?? '',
        'genre': generoPrincipal,
        'type': filme['media_type'] as String? ?? 'movie',
      };
    }).toList();
  }
  Future<List<Map<String,String>>> getCatalog() async {
    final response = await dio.get('/filmes/pesquisar',
    queryParameters: {'q':texto.trim()},
    );
    final results = response.data['results'] as List;
    return results.map<Map<String,String>>((filme){
      final data = filme['release_date'] as String? ?? '';
      final poster = filme['poster_path'] as String?;
      final ids = filme['genre_ids'] as List? ?? [];
      final generoPrincipal = ids.isEmpty ? 'não informado' : generos[ids.first] ?? 'não informado';
      return {
        'id' : filme['id'].toString(),
        'title' : filme['title'] as String? ?? 'Sem título',
        'overview' : filme['overview'] as String? ?? '',
        'year' : data.length >= 4 ? data.substring(0, 4) : '',
        'score' : (filme['vote_average'] as num?)?.toStringAsFixed(1) ?? '0.0',
        'poster_path' : poster == null || poster.isEmpty ? '' : 'https://image.tmdb.org/t/p/w500$poster',
        'genre_ids': filme['genre_ids']?.join(' | ') ?? '',
        'genre': generoPrincipal,
        'type': filme['media_type'] as String? ?? 'movie',
      };
    }).toList();
  }

  // static final mockUsers = <Map<String, String>>[
  //   {
  //     'id': '1',
  //     'name': 'José Silva',
  //     'email': 'jose@teste.com',
  //     'password': '123456',
  //   },
  //   {
  //     'id': '2',
  //     'name': 'Ana Souza',
  //     'email': 'ana@teste.com',
  //     'password': '123456',
  //   },
  //   {
  //     'id': '3',
  //     'name': 'Victor Lima',
  //     'email': 'victor@teste.com',
  //     'password': '123456',
  //   },
  // ];
  Future<void> loginApi(String email, String password) async {
    token = null;
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'senha': password,
        },
      );
      final dados = response.data as Map<String, dynamic>;
      final tokenRecebido = dados['token'] as String?;
      if (tokenRecebido == null || tokenRecebido.isEmpty) {
        throw const FormatException('Token não recebido do servidor.');
      }
      await open(
        dados['email'] as String,
        dados['nome'] as String,
      );

      token = tokenRecebido;
    } on DioException catch (error) {
      final body = error.response?.data;
      throw FormatException(
        body is Map
            ? body['mensagem']?.toString() ?? 'Erro ao efetuar login.'
            : 'Não foi possível conectar ao servidor.',
      );
    }

  }
  Future<void> register(
    String name,
    String email,
    String password,
  )async {
    try{
      await dio.post(
        '/auth/cadastrar',
        data: {
          'nome': name.trim(),
          'email': email.trim().toLowerCase(),
          'senha': password,
        },
      );
    } on DioException catch (error) {
      final body = error.response?.data;

      throw FormatException(
        body is Map ?
        body['message']?.toString() ?? 'Erro ao registrar usuário.': ' Não foi possível conectar ao servidor.',
      );
    }
  }

  // Future<void> register(String name, String email, String password) async {
  //   final normalizedEmail = email.trim().toLowerCase();
  //   if (name.trim().isEmpty ||
  //       !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail) ||
  //       password.length < 6) {
  //     throw const FormatException(
  //       'Informe nome, e-mail válido e senha de pelo menos 6 caracteres.',
  //     );
  //   }
  //   if (mockUsers.any((user) => user['email'] == normalizedEmail)) {
  //     throw const FormatException('Este e-mail já está cadastrado.');
  //   }
  //   mockUsers.add({
  //     'id': normalizedEmail,
  //     'name': name.trim(),
  //     'email': normalizedEmail,
  //     'password': password,
  //   });
  // }

  // Future<void> login(String email, String password) async {
  //   final normalizedEmail = email.trim().toLowerCase();
  //   final matches = mockUsers.where(
  //     (user) =>
  //         user['email'] == normalizedEmail && user['password'] == password,
  //   );
  //   if (matches.isEmpty) {
  //     throw const FormatException('Email ou senha incorretos.');
  //   }
  //   final user = matches.first;
  //   await open(normalizedEmail, user['name']!);
  // }

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

  bool isSaved(Map<String, String> movie) {
    return savedMovies.any((saved) => saved['title'] == movie['title']);
  }

  Review? reviewFor(Map<String, String> movie) {
    for (final review in reviews) {
      if (review.movie['title'] == movie['title']) {
        return review;
      }
    }
    return null;
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

  Future<void> toggleSaved(Map<String, String> movie) async {
    final movies = List<Map<String, String>>.from(savedMovies);
    if (isSaved(movie)) {
      movies.removeWhere((saved) => saved['title'] == movie['title']);
    } else {
      movies.add(movie);
    }
    await _saveLibrary(movies, reviews, userName);
  }

  Future<void> saveReview(
    Map<String, String> movie,
    int rating,
    String comment,
  ) async {
    if (rating < 1 || rating > 10) {
      throw ArgumentError('A nota deve ser de 1 a 10.');
    }
    final movieReviews = List<Review>.from(reviews);
    movieReviews.removeWhere(
      (review) => review.movie['title'] == movie['title'],
    );
    movieReviews.add(
      Review(
        movie: movie,
        rating: rating,
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    await _saveLibrary(savedMovies, movieReviews, userName);
  }

  Future<void> deleteReview(Review review) async {
    final movieReviews = List<Review>.from(reviews);
    movieReviews.removeWhere(
      (item) => item.movie['title'] == review.movie['title'],
    );
    await _saveLibrary(savedMovies, movieReviews, userName);
  }

  Future<void> updateName(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Informe seu nome.');
    }
    await _saveLibrary(savedMovies, reviews, name.trim());
  }
}
