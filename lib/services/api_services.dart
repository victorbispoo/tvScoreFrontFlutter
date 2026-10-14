import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/review.dart';

/// Ponto único para substituir os dados de exemplo por chamadas HTTP.
class ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    return const [
      {
        'title': 'Oppenheimer',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        'year': '2023',
        'score': '8.9',
        'genre': 'Biografia / Drama',
      },
      {
        'title': 'Barbie',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg',
        'year': '2023',
        'score': '7.3',
        'genre': 'Comédia',
      },
      {
        'title': 'Avatar: O Caminho da Água',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg',
        'year': '2022',
        'score': '7.8',
        'genre': 'Ficção Científica',
      },
      {
        'title': 'Homem-Aranha: Através do Aranhaverso',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/8HWnnrO0a4aY18y2rN83g7c88P6.jpg',
        'year': '2023',
        'score': '8.9',
        'genre': 'Animação',
      },
      {
        'title': 'Duna: Parte Dois',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
        'year': '2024',
        'score': '8.5',
        'genre': 'Ficção Científica',
      },
      {
        'title': 'Missão: Impossível - Efeito Fallout',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/AkJQpmRyz9JwX7opAVQby6zyALv.jpg',
        'year': '2018',
        'score': '7.7',
        'genre': 'Ação',
      },
      {
        'title': 'Top Gun: Maverick',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
        'year': '2022',
        'score': '8.3',
        'genre': 'Ação',
      },
      {
        'title': 'Vingadores: Ultimato',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/or06FN3Dka5tukK1e9sl16pB3iy.jpg',
        'year': '2019',
        'score': '8.4',
        'genre': 'Ação',
      },
      {
        'title': 'O Poderoso Chefão',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/3bhkrj58Vtu7enYsRolD1fZdja1.jpg',
        'year': '1972',
        'score': '9.2',
        'genre': 'Crime / Drama',
      },
      {
        'title': 'Pulp Fiction: Tempo de Violência',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/tptX04nGe6P9k9XvN6s1lqE5c1P.jpg',
        'year': '1994',
        'score': '8.9',
        'genre': 'Crime / Drama',
      },
      {
        'title': 'Interestelar',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'year': '2014',
        'score': '8.7',
        'genre': 'Ficção Científica',
      },
      {
        'title': 'Breaking Bad',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
        'year': '2008',
        'score': '9.5',
        'genre': 'Crime / Drama',
        'type': 'series',
        'overview':
            'Um professor de química entra no mundo do crime e transforma a própria vida e a de sua família.',
      },
      {
        'title': 'Stranger Things',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/uOOtwVbSr4QDjAGIifLDwpb2Pdl.jpg',
        'year': '2016',
        'score': '8.7',
        'genre': 'Ficção Científica / Suspense',
        'type': 'series',
        'overview':
            'Um grupo de amigos investiga acontecimentos sobrenaturais e o desaparecimento de um garoto em uma pequena cidade.',
      },
      {
        'title': 'The Last of Us',
        'poster_path':
            'https://image.tmdb.org/t/p/w500/uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg',
        'year': '2023',
        'score': '8.7',
        'genre': 'Drama / Aventura',
        'type': 'series',
        'overview':
            'Em um mundo devastado, um sobrevivente e uma adolescente atravessam o país em uma jornada perigosa.',
      },
    ];
  }

  // Contas fictícias para testes locais, sem persistência.
  static final mockUsers = <Map<String, String>>[
    {
      'id': '1',
      'name': 'José Silva',
      'email': 'jose@teste.com',
      'password': '123456',
    },
    {
      'id': '2',
      'name': 'Ana Souza',
      'email': 'ana@teste.com',
      'password': '123456',
    },
    {
      'id': '3',
      'name': 'Victor Lima',
      'email': 'victor@teste.com',
      'password': '123456',
    },
  ];

  Future<void> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail) ||
        password.length < 6) {
      throw const FormatException(
        'Informe nome, e-mail válido e senha de pelo menos 6 caracteres.',
      );
    }
    if (mockUsers.any((user) => user['email'] == normalizedEmail)) {
      throw const FormatException('Este e-mail já está cadastrado.');
    }
    mockUsers.add({
      'id': normalizedEmail,
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password,
    });
  }

  Future<void> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final matches = mockUsers.where(
      (user) =>
          user['email'] == normalizedEmail && user['password'] == password,
    );
    if (matches.isEmpty) {
      throw const FormatException('Email ou senha incorretos.');
    }
    final user = matches.first;
    await open(normalizedEmail, user['name']!);
  }

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
