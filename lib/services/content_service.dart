part of 'api_services.dart';

extension ContentService on ApiService {
  Future<Map<String, dynamic>> getEpisodePanel(int seriesId) async {
    if (seriesId <= 0) {
      throw ArgumentError('O ID da série deve ser maior que zero.');
    }

    final response = await dio.get('/series/$seriesId/episodios/painel');

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, String>> getContent(int id, String type) async {
    requireContentReference(id, type);

    final resource = type == 'MOVIE' ? 'filmes' : 'series';

    final response = await dio.get('/$resource/$id');

    final data = Map<String, dynamic>.from(response.data as Map);

    return _mapContent(data, type);
  }

  Future<({List<Map<String, String>> contents, int page, int totalPages})>
  searchContents(String query, {int page = 1}) async {
    final term = query.trim();

    if (term.isEmpty) {
      throw ArgumentError('Informe um título para pesquisar.');
    }

    if (page < 1 || page > ApiService.maxSearchPage) {
      throw ArgumentError(
        'A página deve estar entre 1 e ${ApiService.maxSearchPage}.',
      );
    }

    final response = await dio.get(
      '/filmes/pesquisar',
      queryParameters: {'q': term, 'pagina': page},
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final results = data['results'] as List? ?? [];

    final contents = results.map((item) {
      final content = Map<String, dynamic>.from(item as Map);
      return _mapContent(content, content['tipoConteudo'] as String);
    }).toList();

    return (
      contents: contents,
      page: (data['page'] as num).toInt(),
      totalPages: (data['total_pages'] as num).toInt(),
    );
  }

  Map<String, String> _mapContent(Map<String, dynamic> data, String type) {
    final releaseDate = data['release_date'] as String? ?? '';
    final poster = data['poster_path'] as String? ?? '';
    final backdrop = data['backdrop_path'] as String? ?? '';
    final genres = ContentGenres.fromJson(data);
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
      'genre_ids': genres.ids,
      'genre': genres.labels,
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
