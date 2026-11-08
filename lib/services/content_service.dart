part of 'api_services.dart';

extension ContentService on ApiService {
  Future<Map<String, String>> getContent(int id, String type) async {
    if (id <= 0) {
      throw ArgumentError('O ID do conteúdo deve ser maior que zero.');
    }

    if (type != 'MOVIE' && type != 'TV') {
      throw ArgumentError(
        'Tipo de conteúdo inválido. Deve ser "MOVIE" ou "TV".',
      );
    }

    final resource = type == 'MOVIE' ? 'filmes' : 'series';

    final response = await dio.get('/$resource/$id');

    final data = Map<String, dynamic>.from(response.data as Map);

    return _mapContent(data, type);
  }

  Map<String, String> _mapContent(Map<String, dynamic> data, String type) {
    final releaseDate = data['release_date'] as String? ?? '';
    final poster = data['poster_path'] as String? ?? '';
    final backdrop = data['backdrop_path'] as String? ?? '';
    final genreIds = data['genre_ids'] as List? ?? [];

    final mainGenre = genreIds.isEmpty
        ? 'não informado'
        : ApiService.generos[genreIds.first] ?? 'não informado';
    return {
      'id': data['id'].toString(),
      'type': type,
      'title': data['title'] as String? ?? 'Sem titulo',
      'overview': data['overview'] as String? ?? '',
      'year': releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '',
      'score': (data['vote_average'] as num?)?.toStringAsFixed(1) ?? '0.0',
      'poster_path': poster.isEmpty
          ? ''
          : 'https://image.tmdb.org/t/p/w500$poster',
      'backdrop_path': backdrop.isEmpty
          ? ''
          : 'https://image.tmdb.org/t/p/w780$backdrop',
      'genre_ids': genreIds.join(' | '),
      'genre': mainGenre,
    };
  }

  Future<List<Map<String, String>>> getHighlights() async {
    if (ApiService.useMockContents) {
      return mockContents
          .map((content) => Map<String, String>.from(content))
          .toList();
    }
    final responses = await Future.wait([
      dio.get('/filmes/em-alta'),
      dio.get('/series/em-alta'),
    ]);

    final results = [
      ...(responses[0].data['results'] as List),
      ...(responses[1].data['results'] as List),
    ];

    return results.map<Map<String, String>>((item) {
      final data = Map<String, dynamic>.from(item as Map);
      return _mapContent(data, data['tipoConteudo'] as String);
    }).toList();
  }
}
