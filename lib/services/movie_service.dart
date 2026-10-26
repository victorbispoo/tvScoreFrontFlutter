part of 'api_services.dart';

extension MovieService on ApiService {
  Future<List<Map<String, String>>> getHighlights() async {
    if (ApiService.useMockMovies) {
      return mockMovies
          .map((movie) => Map<String, String>.from(movie))
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

    return results.map<Map<String, String>>((filme) {
      final data = filme['release_date'] as String? ?? '';
      final poster = filme['poster_path'] as String?;
      final backdrop = filme['backdrop_path'] as String?;
      final ids = filme['genre_ids'] as List? ?? [];
      final generoPrincipal = ids.isEmpty
          ? 'não informado'
          : ApiService.generos[ids.first] ?? 'não informado';
      return {
        'id': filme['id'].toString(),
        'title': filme['title'] as String? ?? 'Sem título',
        'overview': filme['overview'] as String? ?? '',
        'year': data.length >= 4 ? data.substring(0, 4) : '',
        'score': (filme['vote_average'] as num?)?.toStringAsFixed(1) ?? '0.0',
        'backdrop_path': backdrop == null || backdrop.isEmpty
            ? ''
            : 'https://image.tmdb.org/t/p/w500$backdrop',
        'poster_path': poster == null || poster.isEmpty
            ? ''
            : 'https://image.tmdb.org/t/p/w500$poster',
        'genre_ids': filme['genre_ids']?.join(' | ') ?? '',
        'genre': generoPrincipal,
        'type': filme['tipoConteudo'] == 'TV' ? 'series' : 'movie',
      };
    }).toList();
  }

  // Pendente no arquivo original: Future<Map<String,String>> getMovie
}
